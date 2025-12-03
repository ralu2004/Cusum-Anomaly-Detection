import pandas as pd
import matplotlib.pyplot as plt

def preprocess_temperature_csv(path):
    df = pd.read_csv(path)
    df["Timestamp"] = pd.to_datetime(df["Timestamp"])
    sensor_cols = df.columns[1:]
    df[sensor_cols] = (df[sensor_cols] * 100).round().astype(int)
    return df

def cusum(series, threshold=200, drift=50):
    g_pos = [0]
    g_neg = [0]
    anomalies = []

    for i in range(1, len(series)):
        s = series[i] - series[i - 1]

        g_pos_value = max(g_pos[-1] + s - drift, 0)
        g_neg_value = max(g_neg[-1] - s - drift, 0)

        g_pos.append(g_pos_value)
        g_neg.append(g_neg_value)

        if g_pos_value > threshold or g_neg_value > threshold:
            anomalies.append(i)
            g_pos[-1] = 0
            g_neg[-1] = 0

    return anomalies


def plot_cusum_results(df, column, anomalies):
    plt.figure(figsize=(12, 5))
    plt.plot(df["Timestamp"], df[column], label=column)

    if len(anomalies) > 0:
        plt.scatter(df["Timestamp"].iloc[anomalies],
                    df[column].iloc[anomalies],
                    marker="o", s=70, edgecolors="black", facecolors="red",
                    label="Anomaly", zorder=5)

    plt.title(f"CUSUM Detection: {column}")
    plt.xlabel("Time")
    plt.ylabel("Temperature (×100 integer)")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.show()


def main():
    df = preprocess_temperature_csv("04-12-22_temperature_measurements.csv")
    sensor_cols = df.columns[1:]

    for col in sensor_cols:
        anomalies = cusum(df[col], threshold=200, drift=50)
        print(col, anomalies)

        labels = pd.Series(0, index=df.index)
        labels.iloc[anomalies] = 1

        output_path = f"software_detection_outputs/{col}_labels.csv"
        labels.reset_index().rename(columns={0: "label"}).to_csv(output_path, index=False)

        plot_cusum_results(df, col, anomalies)


if __name__ == "__main__":
    main()
