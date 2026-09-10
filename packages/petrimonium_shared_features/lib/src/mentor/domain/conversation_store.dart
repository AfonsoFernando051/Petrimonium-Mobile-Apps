import 'conversation_summary.dart';

/// The slice of the Mentor repository the conversation-history screen needs.
///
/// Deliberately narrow. Each product's `MentorChatRepository` also sends
/// messages, loads suggested prompts and reaches a pet-preferences repository
/// and its enums — none of which this screen touches, and all of which would
/// otherwise have to move into the package with it. Declaring the three
/// methods it does use keeps the screen shareable without dragging that chain
/// along, and lets a test fake three methods instead of a whole repository.
abstract interface class ConversationStore {
  Future<List<ConversationSummary>> listConversations();

  Future<void> renameConversation(int conversationId, String title);

  Future<void> deleteConversation(int conversationId);
}
