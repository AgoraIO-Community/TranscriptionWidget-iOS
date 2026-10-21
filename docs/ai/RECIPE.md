# iOS Transcription Widget

## Overview

Add a live transcription widget to an iOS RTC app for captions during audio/video calls.

Repository: [AgoraIO-Community/TranscriptionWidget-iOS](https://github.com/AgoraIO-Community/TranscriptionWidget-iOS)

## Prerequisites and Setup

1. Use Xcode and CocoaPods; install the root `Podfile` dependencies and open `AgoraRTT_Demo.xcworkspace`.
2. Configure `AgoraRTT_Demo/KeyCenter.swift` with your project and a reachable, compatible transcription backend. Match the current `ServerEnv` initializer in `AgoraRTT_Demo/MainVC/Manager/AppConfig.swift`.
3. The checked-in KeyCenter initializer omits arguments required by the current ServerEnv initializer. Supply `appId`, `auth` and `useFinalTagAsParagraphDistinction` as appropriate for your backend before building.
4. Select signing and a supported device, configure the desired transcript/translation languages, then start a transcription session.

## What To Check

- Verify interim/final transcript and translation rendering.
- Check history and clearing behavior.
- Stop the session, leave and reopen to confirm no duplicate messages or leaked capture.

## Integration Notes

This reference needs backend configuration and the initializer reconciliation described above. The widget displays service output; it does not supply a transcription backend by itself.

Keep App Certificates, customer secrets and privileged token generation on a trusted backend for production. Use only your own test credentials while configuring historical demos; do not commit them. Preserve the sample's existing dependency versions and lifecycle until a separate migration is tested.

## Source References

- [README.md](../../README.md)
- [Podfile](../../Podfile)
- [AgoraRTT_Demo/KeyCenter.swift](../../AgoraRTT_Demo/KeyCenter.swift)
- [AgoraRTT_Demo/MainVC/Manager/AppConfig.swift](../../AgoraRTT_Demo/MainVC/Manager/AppConfig.swift)

## Validation Status

This recipe was checked against the repository's source and setup documents. The platform build and live service/device flow have not been run as part of this documentation change. Complete the checks above in an environment with the required SDKs, hardware and service access before treating it as a validated deployment.

## Implementation Prompt

```text
You are working in AgoraIO-Community/TranscriptionWidget-iOS. Use docs/ai/RECIPE.md and its linked source files to adapt the iOS Transcription Widget reference to this project.

Start by inspecting the actual sample directory and configuration described above. Resolve its listed missing prerequisites before claiming it is runnable. Preserve the existing architecture and compatible dependency versions. Implement the recipe's feature-specific flow, permissions and resource cleanup. Use a trusted backend for privileged credentials and tokens in production.

Run the repository-specific build or launch flow, then perform each What To Check item. Report the commands run, the observed results and anything blocked by service access, hardware or incomplete sample code. Do not claim live validation from a documentation or catalog build alone.
```
