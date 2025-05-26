import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';
import '../../../models/business.dart';
import '../../../providers/business_provider.dart';
import '../../../api/gemini_service.dart';
import '../../../utils/helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class LegalAdvisorScreen extends StatefulWidget {
  const LegalAdvisorScreen({Key? key}) : super(key: key);

  @override
  State<LegalAdvisorScreen> createState() => _LegalAdvisorScreenState();
}

class _LegalAdvisorScreenState extends State<LegalAdvisorScreen> {
  final _queryController = TextEditingController();

  Business? _selectedBusiness;
  String _legalCategory = 'Business Formation';
  String _response = '';
  List<Map<String, dynamic>> _chatHistory = [];
  bool _isLoading = false;

  final ScrollController _scrollController = ScrollController();

  final List<String> _legalCategories = [
    'Business Formation',
    'Contracts & Agreements',
    'Intellectual Property',
    'Employment Law',
    'Compliance & Regulations',
    'Dispute Resolution',
    'Tax Law',
    'General Legal Advice',
  ];

  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
      setState(() {
        _selectedBusiness = businessProvider.selectedBusiness ??
            (businessProvider.businesses.isNotEmpty ? businessProvider.businesses[0] : null);
      });
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submitQuery() async {
    if (_queryController.text.trim().isEmpty) return;
    if (_selectedBusiness == null) {
      Helpers.showSnackBar(
        context,
        'Please select a business first',
        isError: true,
      );
      return;
    }

    final query = _queryController.text.trim();

    setState(() {
      _chatHistory.add({
        'isUser': true,
        'text': query,
        'timestamp': DateTime.now(),
      });
      _isLoading = true;
    });

    _queryController.clear();
    _scrollToBottom();

    try {
      final prompt = '''
Act as a legal advisor for a ${_selectedBusiness!.industry} business named "${_selectedBusiness!.name}".

Business Description: ${_selectedBusiness!.description}

Legal Category: $_legalCategory

User Query: $query

Previous Conversation:
${_chatHistory.map((msg) => "${msg['isUser'] ? 'User' : 'Advisor'}: ${msg['text']}").join('\n')}

Provide accurate, actionable legal guidance related to the query. Be specific and practical, while making clear that this is general information and not a substitute for personalized legal advice from a qualified attorney. If a question is outside your scope or requires specialized legal expertise, acknowledge this limitation.
''';

      final response = await _geminiService.generateBusinessContent(prompt);

      setState(() {
        _chatHistory.add({
          'isUser': false,
          'text': response,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _chatHistory.add({
          'isUser': false,
          'text': 'Sorry, I encountered an error while processing your request. Please try again.',
          'timestamp': DateTime.now(),
          'isError': true,
        });
        _isLoading = false;
      });

      _scrollToBottom();
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      Helpers.showSnackBar(
        context,
        'Text copied to clipboard',
      );
    }
  }

  void _clearChat() {
    setState(() {
      _chatHistory = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final businessProvider = Provider.of<BusinessProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Legal Advisor',
          style: AppStyles.h2(isDarkMode: isDarkMode),
        ),
        centerTitle: false,
        elevation: 0,
        actions: [
          if (_chatHistory.isNotEmpty)
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Chat'),
                    content: const Text('Are you sure you want to clear the chat history?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          _clearChat();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear Chat',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Business and category selection
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.grey[100],
                border: Border(
                  bottom: BorderSide(
                    color: isDarkMode ? Colors.white12 : Colors.black12,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Business dropdown
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDarkMode ? Colors.white24 : Colors.black12,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Business>(
                          value: _selectedBusiness,
                          isExpanded: true,
                          dropdownColor: isDarkMode ? AppColors.darkCard : Colors.white,
                          hint: Text(
                            'Select Business',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.white54 : Colors.black45,
                            ),
                          ),
                          items: businessProvider.businesses.map((Business business) {
                            return DropdownMenuItem<Business>(
                              value: business,
                              child: Text(
                                business.name,
                                style: TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (Business? value) {
                            setState(() {
                              _selectedBusiness = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Category dropdown
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDarkMode ? Colors.white24 : Colors.black12,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _legalCategory,
                          isExpanded: true,
                          dropdownColor: isDarkMode ? AppColors.darkCard : Colors.white,
                          items: _legalCategories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(
                                category,
                                style: TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? value) {
                            if (value != null) {
                              setState(() {
                                _legalCategory = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Disclaimer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(isDarkMode ? 0.2 : 0.1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This tool provides general legal information, not legal advice. Consult with a qualified attorney for your specific situation.',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Chat history
            Expanded(
              child: _chatHistory.isEmpty
                  ? _buildEmptyState(isDarkMode)
                  : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  final message = _chatHistory[index];
                  return _buildMessageBubble(
                    message['text'] as String,
                    message['isUser'] as bool,
                    message['timestamp'] as DateTime,
                    message['isError'] as bool? ?? false,
                    isDarkMode,
                  );
                },
              ),
            ),

            // Loading indicator
            if (_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Legal advisor is thinking...',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

            // Input area
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkCard : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _queryController,
                      hintText: 'Ask a legal question...',
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitQuery(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppStyles.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _submitQuery,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.balance,
              size: 80,
              color: isDarkMode ? Colors.white38 : Colors.black12,
            ),
            const SizedBox(height: 24),
            Text(
              'Your Legal Advisor',
              style: AppStyles.h2(isDarkMode: isDarkMode),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Ask questions about legal matters for your business. Get guidance on contracts, regulations, intellectual property, and more.',
              style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip('How do I register a company?', isDarkMode),
                _buildSuggestionChip('What should be in my employment contract?', isDarkMode),
                _buildSuggestionChip('Do I need to register a trademark?', isDarkMode),
                _buildSuggestionChip('What are my tax obligations?', isDarkMode),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text, bool isDarkMode) {
    return InkWell(
        onTap: () {
          _queryController.text = text;
          _submitQuery();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
            color: isDarkMode
            ? Colors.white.withOpacity(0.1)
            : Colors.black.withOpacity(0.05),
    borderRadius: BorderRadius.circular