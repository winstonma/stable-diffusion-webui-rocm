import launch
from modules import launch_utils

args = launch_utils.args

def main():
    args.skip_torch_cuda_test = True
    launch.prepare_environment()

if __name__ == "__main__":
    main()
