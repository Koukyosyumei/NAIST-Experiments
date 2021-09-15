######## General settings ########
# cluster setting
node_type="grid_long.q"
gpupernode=1
gpu_mapping_yaml="gpu_mapping.yaml"

# clients setting
client_num=50
client_num_per_round=50
worker_num_pergpu=5

# method
method="AE"

# py file to be executed
py_file="./distributed_main.py"

# model and optimier setting
model="resnet56"
comm_round=55
epochs=5
client_optimizer="adam"
lr=0.001
clip_grad=0
max_norm=1

# dataset setting
dataset="cifar10"
data_dir="/work/hideaki-t/dev/FedML/data/cifar10"
partition_method="pow"
partition_alpha=0.1
batch_size=20

# other settings
frequency_of_the_test=5
ci=0
submit_script=1

######## Method settings ########

## AutoEncoder (AE) settings
autoencoder_lr=0.01
autoencoder_epochs=5
autoencoder_type="STD-NUM-DAGMM"

## RFFL settings
warm_up=5
alpha=0.95
gamma=0.5
sparcity=1
remove=1

## FoolsGold settings
k=0.02
inv=0
indicative_features="all"

## Quality Inferece (QI) settings

######## Adversary settings ########
adversary_num=2
adversary_type="inflator"
inflator_strategy="data_augmentation"
multiple_accounts_split=1.0
ignore_adversary=0
poor_adversary=0

## Free-Rider settings
free_rider_strategy="advanced-delta"
noise_amp=0.001

## Inflator settings
water_powered_magnification=2
inflator_data_size=250
inflator_batch_size=20
inflator_lr_weight=1
num_of_augmentation=0