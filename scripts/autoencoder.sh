#!/bin/sh
#$ -S /bin/bash
# #$ -q pascal_short.q

set -ex

# code checking
# pyflakes .

wandb login 02deeb10aa05ffa5e80eacf94128c7de1156d809 --relogin
wandb online

assert_eq() {
  local expected="$1"
  local actual="$2"
  local msg

  if [ "$expected" == "$actual" ]; then
    return 0
  else
    echo "$expected != $actual"
    return 1
  fi
}

round() {
  printf "%.${2}f" "${1}"
}

# 0. prepare data

cd ../data-generation

TEMP_FOLDER_NAME_1=`mktemp -d --tmpdir=../data`
mkdir $TEMP_FOLDER_NAME_1/train
mkdir $TEMP_FOLDER_NAME_1/test

TEMP_FOLDER_NAME_2=`mktemp -d --tmpdir=../data`
mkdir $TEMP_FOLDER_NAME_2/train
mkdir $TEMP_FOLDER_NAME_2/test

echo "grouping data"
python3 ./grouping.py \
--input_dir /work/hideaki-t/dev/FedML/data/MNIST \
--output_dir $TEMP_FOLDER_NAME_1 \
--group_size 20

echo "flip label"
python3 ./label-flip.py \
--input_dir $TEMP_FOLDER_NAME_1 \
--output_dir $TEMP_FOLDER_NAME_2 \
--flip_ratio 0.3

# 1. MNIST standalone FedAvg
cd ../src/autoencoder

start_time=`date +%s`

# --data_dir ../../../FedML/data/MNIST \

python3 ./main.py \
--gpu 0 \
--dataset mnist \
--data_dir ../$TEMP_FOLDER_NAME_2 \
--model lr \
--partition_method hetero  \
--client_num_in_total 1000 \
--client_num_per_round 10 \
--comm_round 200 \
--epochs 1 \
--batch_size 10 \
--client_optimizer sgd \
--free_rider_num 30 \
--lr 0.03 \
--ci 0

end_time=`date +%s`
run_time=$((end_time - start_time))
echo $run_time

rm -rf ../$TEMP_FOLDER_NAME_1
rm -rf ../$TEMP_FOLDER_NAME_2