node_type="grid_short.q"
client_num=10
client_num_pernode=1
npernode=1
model="resnet56"
dataset="cifar10"
data_dir="/work/hideaki-t/dev/FedML/data/cifar10"
partition_method="hetero"
comm_round=10
epochs=1
client_optimizer="sgd"
batch_size=10
lr=0.1
ci=0

submit_script=0
remove_script=0

np=$((client_num+1))
script_name="autogenerated_npn_${npernode}_np_${np}_m_${model}_ds_${dataset}_cn_${client_num}".sh

echo -ne "#!/bin/sh
#$ -S /bin/bash
#$ -q ${node_type}
#$ -pe mpi $(($np*(24/$npernode)))

module load compiler/gcc/7
module load mpi/openmpi/3.0.0

set -ex

# code checking
# pyflakes .

wandb login 02deeb10aa05ffa5e80eacf94128c7de1156d809 --relogin
wandb online

cd ../../src/distributed

python3 gpu_mapping_yaml_generator.py --client_num $client_num --client_num_pernode $client_num_pernode --npernode $npernode

hostname > mpi_host_file

mpirun -npernode ${npernode} -np ${np} python3 ./distributed_main.py \\
  --gpu_mapping_file \"gpu_mapping.yaml\" \\
  --gpu_mapping_key mapping_config_client_num_${client_num}_client_num_pernode_${client_num_pernode}_npernode_${npernode} \\
  --model ${model} \\
  --dataset ${dataset} \\
  --data_dir ${data_dir} \\
  --partition_method ${partition_method} \\
  --client_num_in_total ${client_num} \\
  --client_num_per_round ${client_num} \\
  --comm_round ${comm_round} \\
  --epochs ${epochs} \\
  --client_optimizer ${client_optimizer} \\
  --batch_size ${batch_size} \\
  --lr ${lr} \\
  --ci ${ci}" > $script_name

qsub $script_name