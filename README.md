# iR Video Tracker

このツールを使うことでiRacingのリプレイ映像から走行データ(走行ライン、速度、ヨー角など)を取得できます。  
次のような活用法が期待されます。

- telemetryを取り忘れたラップの分析をしたい。
- 手元にtelemetryデータのないライバルの走りを分析したい。

## Getting Started

### Prerequisites

- MATLAB
  - Computer Vision Toolbox
  - Image Processing Toolbox
  - MatlabProgressBar
  - matmap3d

### Installing

```bash
git clone https://github.com/Sintaku73/ir-video-tracker.git
```

## Usage and Examples

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

    subgraph "Mu, i2"
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

## Deployment



## Built With



## Contributing



## Versioning



## Authors



## License



## Acknowledgments


