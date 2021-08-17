import argparse
import glob
import json


def agg(input_path, output_path, client_num, max_gap, auxiliary_ratio):

    with open(
        input_path,
        "r",
    ) as inf:
        cdata = json.load(inf)

    # データを一つにまとめる
    all_data = {"x": [], "y": []}
    for uid in cdata["users"]:
        all_data["x"] += cdata["user_data"][uid]["x"]
        all_data["y"] += cdata["user_data"][uid]["y"]
    all_data_num = len(all_data["y"])
    auxiliary_size = int(all_data_num * auxiliary_ratio)
    all_data_num -= auxiliary_size

    # クライアントごとのデータ数の決定
    g = (max_gap - 1) / (client_num - 1)
    gaps = [int(1 + g * i) for i in range(client_num)]
    num_data_list = [int(g * (all_data_num / sum(gaps))) for g in gaps]
    num_data_list[-1] += all_data_num - sum(num_data_list)
    num_data_list = [auxiliary_size] + num_data_list

    print("#### Number of data each client has ####")
    print(num_data_list)

    # データを割り振る
    aggdata = {}
    aggdata["users"] = [f"fagg_{i}" for i in range(client_num + 1)]
    aggdata["num_samples"] = num_data_list
    aggdata["user_data"] = {uid: {"x": [], "y": []} for uid in aggdata["users"]}
    for i in range(1, client_num + 2):
        aggdata["user_data"][f"fagg_{i-1}"]["x"] = all_data["x"][
            sum(num_data_list[: i - 1]) : sum(num_data_list[:i])
        ]
        aggdata["user_data"][f"fagg_{i-1}"]["y"] = all_data["y"][
            sum(num_data_list[: i - 1]) : sum(num_data_list[:i])
        ]

    with open(output_path, "w") as f:
        json.dump(aggdata, f)


def add_args(parser):
    """
    parser : argparse.ArgumentParser
    return a parser added with args required by fit
    """
    # Training settings
    parser.add_argument(
        "--input_dir",
        type=str,
        default="/work/hideaki-t/dev/FedML/data/MNIST",
        metavar="I",
        help="input_path",
    )

    parser.add_argument(
        "--output_dir",
        type=str,
        default="/work/hideaki-t/dev/NAIST-Experiments/data/grouped",
        metavar="O",
        help="output_path",
    )

    parser.add_argument(
        "--client_num",
        type=int,
        default=50,
        metavar="C",
        help="the number of clients",
    )

    parser.add_argument(
        "--max_gap",
        type=int,
        default=20,
        metavar="M",
        help="max gap",
    )

    parser.add_argument(
        "--auxiliary_ratio",
        type=float,
        default=0.01,
        metavar="AR",
        help="auxiliary ratio",
    )

    return parser


if __name__ == "__main__":
    parser = add_args(argparse.ArgumentParser(description="grouping"))
    args = parser.parse_args()

    input_train_json_path = glob.glob(args.input_dir + "/train/*.json")[0]
    input_test_json_path = glob.glob(args.input_dir + "/test/*.json")[0]

    output_train_json_path = args.output_dir + f"/train/train_{args.client_num}.json"
    output_test_json_path = args.output_dir + f"/test/test_{args.client_num}.json"

    agg(
        input_train_json_path,
        output_train_json_path,
        args.client_num,
        args.max_gap,
        args.auxiliary_ratio,
    )
    agg(
        input_test_json_path,
        output_test_json_path,
        args.client_num,
        args.max_gap,
        args.auxiliary_ratio,
    )
