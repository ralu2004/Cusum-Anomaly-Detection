import pandas as pd

def preprocess_temperature_csv(path):
    df = pd.read_csv(path)
    df["Timestamp"] = pd.to_datetime(df["Timestamp"])
    sensor_cols = df.columns[1:]
    df[sensor_cols] = (df[sensor_cols] * 100).round().astype(int)
    return df

def column_to_binary(series):
    return [format(int(value) & 0xFFFFFFFF, "032b") for value in series]
    #return [format(int(value)) for value in series]

def save(filename, binary_list):
    df_output = pd.DataFrame({'binary_value': binary_list})
    df_output.to_csv(filename, index=False)

def main():
    input_csv = "04-12-22_temperature_measurements.csv"
    df = preprocess_temperature_csv(input_csv)
    sensor_cols = df.columns[1:]

    for col in sensor_cols:
        binary_values = column_to_binary(df[col])
        filename = f"{col}_int.csv"
        save(filename, binary_values)


if __name__ == "__main__":
    main()