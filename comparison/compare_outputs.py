import os

software_results = "software_detection_outputs"
hardware_results = "hardware_detection_output"

py_files = os.listdir(software_results)

for file in py_files:
    py_ans = []
    fpga_ans = []
    file_path = os.path.join(software_results, file)

    if os.path.isfile(file_path):
        with open(file_path, 'r') as f:
            first = True
            for line in f:
                if first:          # skip header
                    first = False
                    continue

                line = line.strip().replace(" ", "")  # remove all spaces
                content = line.split(",")
                py_ans.append(int(content[-1]))

        hw_file_path = os.path.join(hardware_results, file)

        with open(hw_file_path, 'r') as f:
            first = True
            for line in f:
                if first:          # skip header
                    first = False
                    continue

                line = line.strip().replace(" ", "")
                content = line.split(",")
                fpga_ans.append(int(content[-1]))

        print("Comparing " + file.replace("_labels.csv", "") + " detection: ")
        diff = sum(1 for a, b in zip(py_ans, fpga_ans) if a != b)
        print("Differences: " + str(diff) + "\n")
