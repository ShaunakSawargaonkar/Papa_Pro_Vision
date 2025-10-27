import 'package:flutter/material.dart';
import 'package:papa_pro_vision/enums.dart';

class MicButton extends StatelessWidget {
  final ConversationState conversationState;
  final Color baseColor;
  final String baseMode;

  const MicButton({
    super.key,
    required this.conversationState,
    required this.baseColor,
    required this.baseMode,
  });

  @override
  Widget build(BuildContext context) {
    final buttonWidth = MediaQuery.of(context).size.width * 0.32;
    return Semantics(
      label: switch (conversationState) {
        ConversationState.listening => 'Stop listening',
        ConversationState.speaking => 'Stop speaking',
        _ => baseMode,
      },
      excludeSemantics: true,
      child: SizedBox(
        width: buttonWidth,
        height: buttonWidth,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(buttonWidth / 2),
            child: Container(
              decoration: BoxDecoration(
                color:
                    conversationState == ConversationState.listening ||
                        conversationState == ConversationState.speaking ||
                        conversationState == ConversationState.videoRecording
                    ? Colors.white
                    : baseColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  switch (conversationState) {
                    ConversationState.listening => Icons.mic_off,
                    ConversationState.speaking => Icons.pause,
                    _ => Icons.mic,
                  },
                  size: buttonWidth * 0.5,
                  color:
                      conversationState == ConversationState.listening ||
                          conversationState == ConversationState.speaking ||
                          conversationState == ConversationState.videoRecording
                      ? baseColor
                      : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
