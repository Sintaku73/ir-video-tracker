# iR Video Tracker

特徴点マッチング[^fm]を用いた画像解析によって、iRacingのリプレイ映像から走行データ(走行ライン、速度、ヨー角など)を取得できます。  
次のような活用法が期待されます。

- telemetryを取り忘れたラップの分析をしたい。
- 手元にtelemetryデータのないライバルの走りを分析したい。

https://github.com/user-attachments/assets/6edf4f84-939c-4b20-92a4-c139eca2fdd9

## Getting Started

### Prerequisites

- [MATLAB](https://www.mathworks.com/products/matlab.html)
  - [Computer Vision Toolbox](https://www.mathworks.com/products/computer-vision.html)
  - [Image Processing Toolbox](https://www.mathworks.com/products/image-processing.html)
  - [MatlabProgressBar](https://www.mathworks.com/matlabcentral/fileexchange/57895-matlabprogressbar)
  - [matmap3d](https://www.mathworks.com/matlabcentral/fileexchange/68480-matmap3d)

### Installing

```bash
git clone https://github.com/Sintaku73/ir-video-tracker.git
```

## Usage and Examples

このツールの使い方は下記フローチャートの通りです:

```mermaid
flowchart TD
s([Start])
e([End])
run["目的のトラックでtelemetryをオンにして走る"]
config["解析用カメラ設定を適用する"]
capture["対象ラップのリプレイを録画する(前後数秒を含む)"]
open["解析したいリプレイを開く"]
config2["解析用カメラ設定を適用する"]
capture2["対象ラップのリプレイを録画する(前後数秒を含む)"]
ibt2mat["telemetryデータを変換する"]
ref["Reference lapを作成する"]
ext["Reference lapとの比較により走行データを抽出する"]
ibt[/*.ibt/]
mat[/*.mat/]
matRef[/*.mat/]
cam[/image_processing.cam/]
cam2[/image_processing.cam/]
mp4[/*.mp4/]
mp4_2[/*.mp4/]
replay[/*.rpy/]
csv[/*.csv/]

s-->run
s-->open
csv-->e

subgraph "Reference lapの準備"
    subgraph ir["iRacing"]
        run-->config
        run-->ibt
        cam-->config
    end

    ibt-->ibt2mat

    subgraph "Mu, i2 Pro"
        ibt2mat-->mat
    end

    config-->capture

    subgraph gb["Game Bar, etc."]
        capture-->mp4
    end
end

subgraph "Target lapの準備"
    subgraph ir2["iRacing"]
        replay-->open-->config2
        cam2-->config2
    end

    config2-->capture2

    subgraph gb2["Game Bar, etc."]
        capture2-->mp4_2
    end
end

subgraph "iR Video Tracker"
    subgraph make_reference_lap.m
        ref-->matRef
    end

    mp4-->ref
    mat-->ref

    matRef-->ext
    mp4-->ext
    mp4_2-->ext

    subgraph extract_driving_data.m
        ext-->csv
    end
end
```

### make_reference_lap.m

リプレイ映像、telemetryデータ[^mu]からトラックマップを生成します。
生成されたデータは`extract_driving.m`でも使用されます。

### extract_driving_data.m

対象ラップのリプレイを`extract_driving_data.m`の出力データと比較することで、対象ラップのtelemetyデータなしに走行データの抽出します。  
出力されるCSVファイルはSteven Daniluk氏の[MotecLogGenerator](https://github.com/stevendaniluk/MotecLogGenerator.git)[^motec]を用いることでi2 Proで読み込める形式に変換できます。

![Visualisation of reference and extraction lap pairs](assets/images/compare_ref_tgt.jpg)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## References

[^fm]: [Automatically Find Image Rotation and Scale](https://www.mathworks.com/help/vision/ug/find-image-rotation-and-scale-using-automated-feature-matching.html)  
    特徴点マッチングについてはこちらのサンプルを参考にしました。
[^mu]: [Mu - Telemetry Exporter for iRacing](https://github.com/patrickmoore/Mu)  
    iRacingで得られたibtファイルの変換に使用しました。
[^motec]: [MotecLogGenerator](https://github.com/stevendaniluk/MotecLogGenerator)  
    [Accessport形式](https://github.com/stevendaniluk/MotecLogGenerator#accessport-logs)での変換に対応しています。
