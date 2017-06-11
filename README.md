# xcsimapps

![Swift 3.1](http://img.shields.io/badge/Swift-3.0.x-orange.svg?style=flat
)
![Platforms](http://img.shields.io/badge/platforms-macOS-lightgrey.svg?style=flat
)

This helps `xcrun simctl ...`. You can list your iOS, watchOS, or tvOS applications of each simulators on your mac:

```shell
$ xcisimapps list apps
...
"jp.bigbamboo.Soratama":
  - "device": "iPhone 6s"
    - "runtime": "com.apple.CoreSimulator.SimRuntime.iOS-10-1"
    - "appName": "Soratama"
    - "appContainerPath": "/Users/takayoshi/Library/Developer/CoreSimulator/Devices/B6D29324-E29E-499A-BA8C-E38049F52118/data/Containers/Bundle/Application/E0DE9AC7-C2AB-4775-BF8F-2117FF630B96"
    - "dataContainerPath": "/Users/takayoshi/Library/Developer/CoreSimulator/Devices/B6D29324-E29E-499A-BA8C-E38049F52118/data/Containers/Data/Application/143DA7C7-0461-4B99-AD4F-2C192C8F83D4"
  - "device": "iPhone SE"
    - "runtime": "com.apple.CoreSimulator.SimRuntime.iOS-10-1"
    - "appName": "Soratama"
    - "appContainerPath": "/Users/takayoshi/Library/Developer/CoreSimulator/Devices/82102F4D-4841-4689-ABD9-31799FADDA96/data/Containers/Bundle/Application/B2D62B29-CC62-43DC-8549-36E0E0279405"
    - "dataContainerPath": "/Users/takayoshi/Library/Developer/CoreSimulator/Devices/82102F4D-4841-4689-ABD9-31799FADDA96/data/Containers/Data/Application/1B4A64C2-C6DA-49FC-BA61-612538B136F4"
  - "device": "iPhone SE"
    - "runtime": "iOS 10.3"
    - "appName": "Soratama"
    - "appContainerPath": "/Users/takayoshi/Library/Developer/CoreSimulator/Devices/5F786096-736F-4702-817C-722D7B3268CD/data/Containers/Bundle/Application/0AD86986-B759-45DC-ABD7-C1866F874DBA"
    - "dataContainerPath": "/Users/takayoshi/Library/Developer/CoreSimulator/Devices/5F786096-736F-4702-817C-722D7B3268CD/data/Containers/Data/Application/9AE85463-C482-45CA-A28A-3DDCF1DA9881"
...
```

## Usage

```shell
Usage: xcsimapps [options] <subcommands> ...

Options:
   -h, --help  Show this help message and exit
   --version   Show the xcsimapps version

Subcommands:
   list        List available apps, devices, runtimes
   data        Show the data container directory path of the app
```

```shell
Usage: xcsimapps list [-h|--help] [apps|devices|runtimes] ...
```

```shell
Usage: xcsimapps list apps [-h|--help] [-available] [-a|--app <app-identifier>] [-d|--device <device-name>] [-r|--runtime <runtime>]
```

```shell
Usage: xcsimapps data [-h|--help] -a|--app <app-identifier> -d|--device <device-name> -r|--runtime <runtime>
```

**e.g. Open data container directory with finder:**

```shell
$ open `xcsimapps data -a jp.bigbamboo.Soratama -d "iPhone SE" -r "iOS 10.3"`
```

**e.g. Show data container directory with ls:**

```shell
$ ls `./xcsimapps data -a jp.bigbamboo.Soratama -d "iPhone SE" -r "iOS 10.3"` -1
Documents
Library
tmp
```

## Build

Requires Xcode >= 8.3.1.
