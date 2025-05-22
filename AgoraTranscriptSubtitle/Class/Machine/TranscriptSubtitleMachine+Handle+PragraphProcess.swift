//
//  TranscriptSubtitleMachine+Handle+PostProcess.swift
//  AgoraTranscriptSubtitle
//
//  Created by ZYP on 2024/6/27.
//

import Foundation

extension TranscriptSubtitleMachine { /** handle message for Paragraph **/
    
    func _handleTranscriptPostProcess(message: ProtobufDeserializer.DataStreamMessage, uid: UidType) {
        var intermediateInfos = intermediateInfoCache.getAllInfo(uid: uid)
        if let lastOne = intermediateInfos.last, lastOne.transcriptInfo.paragraphEnd == false { /** append **/
            let infos = infoCache.getAllInfo(uid: uid)
            let willMergeInfos = TranscriptSubtitleMachine.searchLastTranscriptMergeInfos(infos: infos)
            lastOne.transcriptInfo.words = willMergeInfos.map({ $0.transcriptInfo.words }).flatMap({ $0 })
            lastOne.transcriptInfo.textTs = message.textTs
            lastOne.transcriptInfo.sentenceEndIndex = message.sentenceEndIndex
            let renderInfo = convertToRenderInfo(uid: message.uid,
                                                 info: lastOne,
                                                 useTranscriptText: showTranscriptContent)
            invokeUpdate(self, renderInfo: renderInfo)
        }
        else { /** add **/
            let words = message.words.map({ $0.splitToTranscriptWords }).flatMap({ $0 })
            let transcriptInfo = TranscriptInfo()
            transcriptInfo.startMs = message.textTs
            transcriptInfo.textTs = message.textTs
            transcriptInfo.sentenceEndIndex = message.sentenceEndIndex
            transcriptInfo.duration = message.durationMs
            transcriptInfo.words = words
            let info = Info(transcriptInfo: transcriptInfo, translateInfos: [])
            intermediateInfoCache.addInfo(uid: uid, info: info)
            let renderInfo = convertToRenderInfo(uid: message.uid,
                                                 info: info,
                                                 useTranscriptText: showTranscriptContent)
            invokeUpdate(self, renderInfo: renderInfo)
        }
        
        intermediateInfos = intermediateInfoCache.getAllInfo(uid: uid)
        debug_intermediateDelegate?.debugMachineIntermediate(self, diduUpdate: intermediateInfos)
    }
    
    func _handleTranslatePostProcess(message: ProtobufDeserializer.DataStreamMessage, uid: UidType) {
        
        let words = (message.transArray as! [SttTranslation]).map({ TranslateWord(sttTranslation: $0) })
        
        if let specificOne = intermediateInfoCache.getLast(uid: uid, with: message.textTs) { /** append */
            let infos = infoCache.getAllInfo(uid: uid)
            var willMergeInfos = TranscriptSubtitleMachine.searchTranslateMergeInfos(infos: infos, textTs: message.textTs)
            updateTranslateInfo_Post(intermediateInfo: specificOne, willMergeInfos: willMergeInfos)
            let renderInfo = convertToRenderInfo(uid: message.uid,
                                                 info: specificOne,
                                                 useTranscriptText: showTranscriptContent)
            invokeUpdate(self, renderInfo: renderInfo)
            return
        }
        
        Log.errorText(text: "can not find a transcript message before a translate message: \(message.jsonString)", tag: logTag)
    }
}
