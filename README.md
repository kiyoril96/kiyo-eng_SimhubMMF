# kiyo-eng_SimhubMMF
SimhubのMMFレンダリングをAssettocorsaのCSPLuaから読み取って表示するアプリです。

## 使用イメージ
<p>
<img width=30% alt="image" src="https://github.com/user-attachments/assets/917cbcda-fee8-4919-9e34-5fef68022d7b" />
<img width=27% alt="image" src="https://github.com/user-attachments/assets/46054a01-263f-49ea-b3dd-2413cda61f9a" />
<img width=31% alt="image" src="https://github.com/user-attachments/assets/d8dc3fd5-3d71-4707-8e51-54f560ac1d0e" />
</p>

## MMF?
* Simhubで定義したデバイスにメモリ経由で情報を送る仕組みが追加されてました
* 本家もC#で別アプリから読みだすソフトウェアサンプルを公開していて、それを移植した形です
* [本家](https://manual.simhubdash.com/device-definition-authoring/supported-screens#mmf-rendering) 実装とかはこっちを見てもらった方がいいと思います。

## 使い方

### 用意するもの
* AssettoCorsa
* ContentsManager
* CSP 0.2.11 以上 (それ以前テストしてないだけ)
* Simhub 9.11.0以上 (フリー版可否は未確認 だけど行ける気がする)

### LuaApp のインストール
コンテンツマネージャにドラッグアンドドロップでインストールできるはずです。

### Simhubデバイスのインストール
* 同梱している AssettocorsaVirtualDisplay.shdd をダブルクリックしてください。 ガイドに沿ってインストールできるはずです。
* AssettocorsaVirtualDisplay.shdp はLEDの個数増やしたいとか無ければ使いません。

### アプリ の使い方
* SimHubは先につけておいてください。
* アセコルを起動したら「kiyo-eng_SimHubMMF」を探してください。
* 上手く行けばすぐ、行かなければ（大抵はいかないんですが）5秒ほど待つとSimhub側で設定したダッシュボードが見えるはずです。
* 3Dモデルがすでに読み込まれています。おおかた変なところにあるので、UIの下の方にあるスライダをぐりぐり動かして探してください。
* もしくはAttachTo を「STEER_HR」にするとステアリングにくっつきます。見つけられなくてもZかYを動かしたら出てくるはずです。
* 反対を向いていたら「Flip」、上下逆さまなら「Invert」をチェックしてください。
* UIの映像と、3Dモデルもタッチ操作が可能です。UIからボタン操作が可能です。ダッシュボード切り替え、明るさ調整などはSimhubのコントロールから操作できます。
* まだ位置の保存はできません。SimHubからの映像とLEDも1種類だけです。（最大10使える）
* ダッシュボード切り替えはSimHubのDevices⇒AssettocorsaVirtualDisplay⇒LCD⇒Dashbordから切り替えます
* タッチモード設定はSimHubのDevices⇒AssettocorsaVirtualDisplay⇒LCD⇒Hardware⇒Screen settings⇒Touchscreenから操作してください。
* LEDプロファイルはSimHubのDevices⇒AssettocorsaVirtualDisplay⇒LEDから操作してください。一応いくつかデフォルト設定を入れておきました。

### 3Dモデルについて
* モデルの構造は結構単純なので各自で作って遊ぶこともできると思います。
* ダッシュボードが欲しかったら「Display」というマテリアルを用意して、16:9のUVを割り当ててください
* LEDが欲しかったら任意のモデルに「LED.XXX」というマテリアルを割り当ててください。（XXXは1スタートの連番にしてください。）色はなんでもいいです。
* LEDを増やしたい場合は AssettocorsaVirtualDisplay.shdp をSimhubにインポートして、デバイス定義を調整する必要があります。

### Simhubデバイス定義プロジェクトファイルについて
* AssettocorsaVirtualDisplay.shdpです。SimhubのDevices⇒Utilities⇒Device definition authoring tool ⇒ Importから読み込んでください。
* Assettocorsa VirtualDisplay のEditから編集に入ります。
* Ledsのセクションで好きなように割り当ててください。
* 初期設定だと真ん中9つがTelemetry 左右3つずつがAccessory としています。
* 数を変更したらPhysical LED organizationを合計数になるように調整し、Physical mappingのところにあるボタンからマッピングを行ってください。
* マッピング画面で割り当てたインデックスが3Dモデルのマテリアルのインデックスと対応します。
* 出来上がったらSaveして More⇒Instantiateをするとデバイスが使えるようになると思います。
