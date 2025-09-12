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
    return Semantics(
      label: switch (conversationState) {
        ConversationState.listening => 'Stop listening',
        ConversationState.speaking => 'Stop speaking',
        _ => baseMode,
      },
      excludeSemantics: true,
      child: SizedBox(
        width: 120, // Custom size - adjust as needed
        height: 120, // Custom size - adjust as needed
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(60),
            child: Container(
              decoration: BoxDecoration(
                color:
                    conversationState == ConversationState.listening ||
                        conversationState == ConversationState.speaking
                    ? Colors.white
                    : baseColor,
                shape: BoxShape.circle,
                border: Border.all(color: baseColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  switch (conversationState) {
                    ConversationState.listening => Icons.mic_off,
                    ConversationState.speaking => Icons.pause,
                    _ => Icons.mic,
                  },
                  size: 60, // Larger icon size
                  color:
                      conversationState == ConversationState.listening ||
                          conversationState == ConversationState.speaking
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
