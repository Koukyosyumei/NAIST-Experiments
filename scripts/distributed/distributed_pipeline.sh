node_type=$1
client_num=$2
client_num_pernode=$3
npernode=$4
py_file=$5
gpu_mapping_yaml=$6
model=$7
dataset=$8
data_dir=$9
partition_method=${10}
partition_alpha=${11}
comm_round=${12}
epochs=${13}
client_optimizer=${14}
batch_size=${15}
lr=${16}
ci=${17}
submit_script=${18}

# check the arguments

echo "node_type=${node_type}"
echo "client_num=${client_num}"
echo "client_num_pernode=${client_num_pernode}"
echo "npernode=${npernode}"
echo "py_file=${py_file}"
echo "gpu_mapping_yaml=${gpu_mapping_yaml}"
echo "model=${model}"
echo "dataset=${dataset}"
echo "data_dir=${data_dir}"
echo "partition_method=${partition_method}"
echo "comm_round=${comm_round}"
echo "epochs=${epochs}"
echo "client_optimizer=${client_optimizer}"
echo "batch_size=${batch_size}"
echo "lr=${lr}"
echo "ci=${ci}"
echo "submit_script=${submit_script}"

# preparation

if [ $(((client_num+1)%client_num_pernode)) -eq 0 ]; then
  temp=0
else
  temp=1
fi
np=$((((client_num+1)/client_num_pernode)+temp))

script_name="autogenerated_npn_${npernode}_np_${np}_m_${model}_ds_${dataset}_cn_${client_num}".sh
output_dir="output_autogenerated_npn_${npernode}_np_${np}_m_${model}_ds_${dataset}_cn_${client_num}"
wandb_api_key=`cat ../wandb_api_key.txt`

# auto-generate a script

echo -ne "#!/bin/sh
#$ -S /bin/bash
#$ -q ${node_type}
#$ -pe mpi $(($np*(24/$npernode)))

module load compiler/gcc/7
module load mpi/openmpi/3.0.0

function cleanup_exit() {
  pkill FedAvg
}

trap cleanup_exit SIGUSR2

set -ex

# code checking
# pyflakes .

wandb login ${wandb_api_key} --relogin
wandb online

cd ../../src/distributed

python3 gpu_mapping_yaml_generator.py --client_num $client_num --client_num_pernode $client_num_pernode --npernode $npernode

hostname > mpi_host_file

if [ ! -e ${output_dir} ]; then
  mkdir ${output_dir}
fi

mpirun -np ${np} -npernode ${npernode} python3 ${py_file} \\
  --gpu_mapping_file ${gpu_mapping_yaml} \\
  --gpu_mapping_key mapping_config_client_num_${client_num}_client_num_pernode_${client_num_pernode}_npernode_${npernode} \\
  --model ${model} \\
  --dataset ${dataset} \\
  --data_dir ${data_dir} \\
  --partition_method ${partition_method} \\
  --partition_alpha ${partition_alpha} \\
  --client_num_in_total ${client_num} \\
  --client_num_per_round ${client_num} \\
  --comm_round ${comm_round} \\
  --epochs ${epochs} \\
  --client_optimizer ${client_optimizer} \\
  --batch_size ${batch_size} \\
  --lr ${lr} \\
  --ci ${ci} \\
  --output_dir ${output_dir}
  
mpirun -npernode ${npernode} -np ${np} ps aux | grep FedAvg
mpirun -npernode ${npernode} -np ${np} pkill FedAvg
mpirun -npernode ${npernode} -np ${np} ps aux | grep FedAvg" > $script_name

# submit the auto-generated script
if [ $submit_script -eq 1 ] ; then
  qsub -notify $script_name
fi