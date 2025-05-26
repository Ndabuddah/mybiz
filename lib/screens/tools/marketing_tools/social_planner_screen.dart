import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../api/gemini_service.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_styles.dart';
import '../../../models/business.dart';
import '../../../providers/business_provider.dart';
import '../../../utils/helper.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';

class SocialPlannerScreen extends StatefulWidget {
  const SocialPlannerScreen({Key? key}) : super(key: key);

  @override
  State<SocialPlannerScreen> createState() => _SocialPlannerScreenState();
}

class _SocialPlannerScreenState extends State<SocialPlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetAudienceController = TextEditingController();
  final _goalsController = TextEditingController();
  final _contentStyleController = TextEditingController();

  Business? _selectedBusiness;
  List<String> _selectedPlatforms = [];
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  List<Map<String, dynamic>> _generatedPlan = [];
  bool _isLoading = false;
  bool _isPlanGenerated = false;

  final List<Map<String, dynamic>> _socialPlatforms = [
    {'name': 'Instagram', 'icon': Icons.camera_alt},
    {'name': 'Facebook', 'icon': Icons.facebook},
    {'name': 'Twitter', 'icon': Icons.chat},
    {'name': 'LinkedIn', 'icon': Icons.work},
    {'name': 'TikTok', 'icon': Icons.music_note},
    {'name': 'YouTube', 'icon': Icons.play_arrow},
    {'name': 'Pinterest', 'icon': Icons.push_pin},
  ];

  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessProvider = Provider.of<BusinessProvider>(context, listen: false);
      setState(() {
        _selectedBusiness = businessProvider.selectedBusiness ?? (businessProvider.businesses.isNotEmpty ? businessProvider.businesses[0] : null);
      });
    });
  }

  @override
  void dispose() {
    _targetAudienceController.dispose();
    _goalsController.dispose();
    _contentStyleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: isStartDate ? _startDate : _endDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Ensure end date is after start date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          if (picked.isAfter(_startDate)) {
            _endDate = picked;
          } else {
            Helpers.showSnackBar(context, 'End date must be after start date', isError: true);
          }
        }
      });
    }
  }

  Future<void> _generateSocialPlan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBusiness == null) {
      Helpers.showSnackBar(context, 'Please select a business first', isError: true);
      return;
    }

    if (_selectedPlatforms.isEmpty) {
      Helpers.showSnackBar(context, 'Please select at least one social platform', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _isPlanGenerated = false;
      _generatedPlan = [];
    });

    try {
      final prompt = '''
Create a detailed 30-day social media content plan for a ${_selectedBusiness!.industry} business named "${_selectedBusiness!.name}".

Business Description: ${_selectedBusiness!.description}
Target Audience: ${_targetAudienceController.text}
Goals: ${_goalsController.text}
Content Style/Tone: ${_contentStyleController.text}
Selected Platforms: ${_selectedPlatforms.join(', ')}
Date Range: ${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d').format(_endDate)}

Generate a day-by-day content plan with the following details for each day:
1. Date
2. Day of week
3. Platform(s)
4. Content type (e.g., image, video, carousel, story, poll)
5. Content topic/theme
6. Caption suggestion (brief)
7. Hashtag suggestions
8. Best posting time

The plan should be strategically balanced across the selected platforms, with appropriate content types for each platform. Include a mix of promotional, educational, entertaining, and engaging content. Consider content themes that align with the business goals and resonate with the target audience.

Format the output as structured JSON data with one object per day, containing all the information above.
''';

      final response = await _geminiService.generateBusinessContent(prompt);

      // Try to parse the response as JSON
      try {
        // Extract just the JSON part if there's surrounding text
        final jsonString = _extractJsonFromText(response);
        final List<dynamic> parsedPlan = jsonDecode(jsonString);

        // Convert to a list of maps
        final formattedPlan = parsedPlan.map((item) => item as Map<String, dynamic>).toList();

        setState(() {
          _generatedPlan = formattedPlan;
          _isPlanGenerated = true;
        });
      } catch (e) {
        // If JSON parsing fails, generate a formatted plan from the text
        setState(() {
          _generatedPlan = _parseTextToStructuredPlan(response);
          _isPlanGenerated = true;
        });
      }
    } catch (e) {
      Helpers.showSnackBar(context, 'Error generating social plan: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _extractJsonFromText(String text) {
    // Try to extract JSON if it's wrapped in markdown code blocks
    final jsonRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = jsonRegex.firstMatch(text);

    if (match != null && match.groupCount >= 1) {
      return match.group(1)!.trim();
    }

    // If no markdown blocks, return the original text
    return text;
  }

  List<Map<String, dynamic>> _parseTextToStructuredPlan(String text) {
    // If JSON parsing failed, create a structured format from the text
    // This is a fallback to handle non-JSON formatted responses
    final lines = text.split('\n');
    final List<Map<String, dynamic>> result = [];

    Map<String, dynamic>? currentDay;
    for (final line in lines) {
      final trimmedLine = line.trim();

      // Skip empty lines
      if (trimmedLine.isEmpty) continue;

      // Check if this is a new day entry (usually starts with a date)
      if (trimmedLine.contains('Day') || _isDateLine(trimmedLine)) {
        // Save previous day if exists
        if (currentDay != null && currentDay.isNotEmpty) {
          result.add(currentDay);
        }

        // Start a new day
        currentDay = {'date': _extractDate(trimmedLine), 'day': _extractDayOfWeek(trimmedLine), 'platforms': [], 'contentType': '', 'topic': '', 'caption': '', 'hashtags': [], 'postTime': ''};
      } else if (currentDay != null) {
        // Parse the details of the current day
        if (trimmedLine.startsWith('Platform') || trimmedLine.contains('Platform:')) {
          currentDay['platforms'] = _extractList(trimmedLine.split(':').last);
        } else if (trimmedLine.startsWith('Content Type') || trimmedLine.contains('Content Type:')) {
          currentDay['contentType'] = trimmedLine.split(':').last.trim();
        } else if (trimmedLine.startsWith('Topic') || trimmedLine.contains('Topic:') || trimmedLine.startsWith('Theme') || trimmedLine.contains('Theme:')) {
          currentDay['topic'] = trimmedLine.split(':').last.trim();
        } else if (trimmedLine.startsWith('Caption') || trimmedLine.contains('Caption:')) {
          currentDay['caption'] = trimmedLine.split(':').last.trim();
        } else if (trimmedLine.startsWith('Hashtag') || trimmedLine.contains('Hashtags:')) {
          currentDay['hashtags'] = _extractList(trimmedLine.split(':').last);
        } else if (trimmedLine.startsWith('Post Time') || trimmedLine.contains('Post Time:') || trimmedLine.startsWith('Time') || trimmedLine.contains('Time:')) {
          currentDay['postTime'] = trimmedLine.split(':').last.trim();
        }
      }
    }

    // Add the last day if exists
    if (currentDay != null && currentDay.isNotEmpty) {
      result.add(currentDay);
    }

    return result;
  }

  bool _isDateLine(String line) {
    // Check if the line appears to contain a date
    return RegExp(r'\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\b').hasMatch(line) || RegExp(r'\b\d{1,2}/\d{1,2}\b').hasMatch(line);
  }

  String _extractDate(String line) {
    // Extract date from the line
    final dateRegex = RegExp(r'\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[\s\.]?(\d{1,2})\b');
    final dateMatch = dateRegex.firstMatch(line);

    if (dateMatch != null) {
      return '${dateMatch.group(1)} ${dateMatch.group(2)}';
    }

    // Try numeric format
    final numericDateRegex = RegExp(r'\b(\d{1,2})/(\d{1,2})\b');
    final numericMatch = numericDateRegex.firstMatch(line);

    if (numericMatch != null) {
      return '${numericMatch.group(1)}/${numericMatch.group(2)}';
    }

    // Extract day number if available
    final dayNumberRegex = RegExp(r'Day\s+(\d+)');
    final dayNumberMatch = dayNumberRegex.firstMatch(line);

    if (dayNumberMatch != null) {
      final dayNumber = int.parse(dayNumberMatch.group(1)!);
      final date = _startDate.add(Duration(days: dayNumber - 1));
      return DateFormat('MMM d').format(date);
    }

    return 'Unknown Date';
  }

  String _extractDayOfWeek(String line) {
    // Extract day of week from the line
    final daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    for (final day in daysOfWeek) {
      if (line.contains(day)) {
        return day;
      }
    }

    // If no day of week found, try to calculate it from the date
    final dateRegex = RegExp(r'\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[\s\.]?(\d{1,2})\b');
    final dateMatch = dateRegex.firstMatch(line);

    if (dateMatch != null) {
      final month = _monthToNumber(dateMatch.group(1)!);
      final day = int.parse(dateMatch.group(2)!);
      final year = _startDate.year;

      final date = DateTime(year, month, day);
      return DateFormat('EEEE').format(date);
    }

    return 'Unknown';
  }

  int _monthToNumber(String month) {
    const months = {'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12};

    return months[month] ?? 1;
  }

  List<String> _extractList(String text) {
    // Extract a list of items from comma-separated or hashtag-formatted text
    if (text.contains('#')) {
      final hashtags = RegExp(r'#\w+').allMatches(text).map((m) => m.group(0)!).toList();
      return hashtags.isNotEmpty ? hashtags : [text.trim()];
    } else {
      return text.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      Helpers.showSnackBar(context, 'Text copied to clipboard');
    }
  }

  void _resetForm() {
    setState(() {
      _targetAudienceController.clear();
      _goalsController.clear();
      _contentStyleController.clear();
      _selectedPlatforms = [];
      _generatedPlan = [];
      _isPlanGenerated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final businessProvider = Provider.of<BusinessProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Social Media Planner', style: AppStyles.h2(isDarkMode: isDarkMode)), centerTitle: false, elevation: 0),
      body: SafeArea(child: _isLoading ? const Center(child: CircularProgressIndicator()) : Form(key: _formKey, child: _isPlanGenerated ? _buildGeneratedPlanView(isDarkMode) : _buildPlanGeneratorForm(isDarkMode, businessProvider))),
    );
  }

  Widget _buildPlanGeneratorForm(bool isDarkMode, BusinessProvider businessProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business selection
          Text('Business', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Business>(
                value: _selectedBusiness,
                isExpanded: true,
                dropdownColor: isDarkMode ? AppColors.darkCard : Colors.white,
                hint: Text('Select Business', style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black45)),
                items:
                    businessProvider.businesses.map((Business business) {
                      return DropdownMenuItem<Business>(value: business, child: Text(business.name));
                    }).toList(),
                onChanged: (Business? value) {
                  setState(() {
                    _selectedBusiness = value;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Date range
          Text('Date Range', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
                    child: Row(children: [Icon(Icons.calendar_today, size: 16, color: isDarkMode ? Colors.white54 : Colors.black45), const SizedBox(width: 8), Text(DateFormat('MMM d, yyyy').format(_startDate))]),
                  ),
                ),
              ),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('to')),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12)),
                    child: Row(children: [Icon(Icons.calendar_today, size: 16, color: isDarkMode ? Colors.white54 : Colors.black45), const SizedBox(width: 8), Text(DateFormat('MMM d, yyyy').format(_endDate))]),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Social platforms
          Text('Social Platforms', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _socialPlatforms.map((platform) {
                  final isSelected = _selectedPlatforms.contains(platform['name']);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedPlatforms.remove(platform['name']);
                        } else {
                          _selectedPlatforms.add(platform['name']);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryColor : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03)),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: isSelected ? AppColors.primaryColor : (isDarkMode ? Colors.white24 : Colors.black12)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Icon(platform['icon'], size: 16, color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black54)), const SizedBox(width: 8), Text(platform['name'], style: TextStyle(color: isSelected ? Colors.white : (isDarkMode ? Colors.white : Colors.black)))],
                      ),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 16),

          // Target audience
          Text('Target Audience', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _targetAudienceController,
            hintText: 'Describe your target audience',
            prefixIcon: Icons.people,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please describe your target audience';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Goals
          Text('Social Media Goals', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _goalsController,
            hintText: 'What do you want to achieve with social media?',
            prefixIcon: Icons.flag,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your social media goals';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Content style
          Text('Content Style/Tone', style: AppStyles.bodyMedium(isDarkMode: isDarkMode).copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _contentStyleController,
            hintText: 'Describe your preferred content style and tone',
            prefixIcon: Icons.style,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please describe your content style/tone';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Generate button
          SizedBox(width: double.infinity, child: CustomButton(text: 'Generate Social Media Plan', icon: Icons.calendar_month, onPressed: _generateSocialPlan, type: ButtonType.primary)),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGeneratedPlanView(bool isDarkMode) {
    return Column(
      children: [
        // Plan header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primaryColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Social Media Plan', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              if (_selectedBusiness != null) Text('For: ${_selectedBusiness!.name}', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16)),
              Text('${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d').format(_endDate)}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
            ],
          ),
        ),

        // Calendar view
        Expanded(
          child:
              _generatedPlan.isEmpty
                  ? Center(child: Text('No content plan generated', style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black45)))
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _generatedPlan.length,
                    itemBuilder: (context, index) {
                      final day = _generatedPlan[index];
                      return _buildDayCard(day, isDarkMode);
                    },
                  ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: isDarkMode ? AppColors.darkCard : Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
          child: Row(
            children: [
              Expanded(child: CustomButton(text: 'New Plan', icon: Icons.refresh, onPressed: _resetForm, type: ButtonType.outline)),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: 'Export',
                  icon: Icons.ios_share,
                  onPressed: () {
                    final planText = _formatPlanAsText();
                    _copyToClipboard(planText);
                  },
                  type: ButtonType.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day, bool isDarkMode) {
    final date = day['date'] ?? 'Unknown Date';
    final dayOfWeek = day['day'] ?? 'Unknown Day';
    final platforms = day['platforms'] ?? [];
    final contentType = day['contentType'] ?? '';
    final topic = day['topic'] ?? '';
    final caption = day['caption'] ?? '';
    final hashtags = day['hashtags'] ?? [];
    final postTime = day['postTime'] ?? '';

    // Convert platforms to List<String> if it's not already
    final List<String> platformsList = platforms is List ? platforms.map((p) => p.toString()).toList() : [platforms.toString()];

    // Convert hashtags to List<String> if it's not already
    final List<String> hashtagsList = hashtags is List ? hashtags.map((h) => h.toString()).toList() : [hashtags.toString()];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDarkMode ? 0 : 2,
      color: isDarkMode ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and platforms
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [Text(date, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryColor)), Text(dayOfWeek, style: TextStyle(fontSize: 12, color: AppColors.primaryColor))]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Platforms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black54)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children:
                            platformsList.map((platform) {
                              return Chip(
                                label: Text(platform, style: TextStyle(fontSize: 10, color: Colors.white)),
                                backgroundColor: _getPlatformColor(platform),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Content details
            _buildDetailRow('Content Type', contentType, Icons.category, isDarkMode),
            const SizedBox(height: 8),
            _buildDetailRow('Topic/Theme', topic, Icons.topic, isDarkMode),
            const SizedBox(height: 8),
            _buildDetailRow('Post Time', postTime, Icons.access_time, isDarkMode),
            const SizedBox(height: 16),

            // Caption
            Text('Caption Suggestion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(8)), child: Text(caption, style: TextStyle(fontSize: 14))),
            const SizedBox(height: 16),

            // Hashtags
            Text('Hashtags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children:
                  hashtagsList.map((hashtag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                      child: Text(hashtag.startsWith('#') ? hashtag : '#$hashtag', style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black54)),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: isDarkMode ? Colors.white54 : Colors.black45),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black54)), Text(value, style: TextStyle(fontSize: 14))])),
      ],
    );
  }

  Color _getPlatformColor(String platform) {
    final platform_ = platform.toLowerCase();
    if (platform_.contains('instagram')) {
      return Color(0xFFE1306C);
    } else if (platform_.contains('facebook')) {
      return Color(0xFF1877F2);
    } else if (platform_.contains('twitter') || platform_.contains('x')) {
      return Color(0xFF1DA1F2);
    } else if (platform_.contains('linkedin')) {
      return Color(0xFF0077B5);
    } else if (platform_.contains('tiktok')) {
      return Color(0xFF000000);
    } else if (platform_.contains('youtube')) {
      return Color(0xFFFF0000);
    } else if (platform_.contains('pinterest')) {
      return Color(0xFFE60023);
    } else {
      return AppColors.primaryColor;
    }
  }

  String _formatPlanAsText() {
    final buffer = StringBuffer();

    buffer.writeln('SOCIAL MEDIA PLAN FOR ${_selectedBusiness?.name}');
    buffer.writeln('${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d').format(_endDate)}');
    buffer.writeln('');

    for (final day in _generatedPlan) {
      final date = day['date'] ?? 'Unknown Date';
      final dayOfWeek = day['day'] ?? 'Unknown Day';
      final platforms = day['platforms'] ?? [];
      final contentType = day['contentType'] ?? '';
      final topic = day['topic'] ?? '';
      final caption = day['caption'] ?? '';
      final hashtags = day['hashtags'] ?? [];
      final postTime = day['postTime'] ?? '';

      buffer.writeln('$date ($dayOfWeek)');
      buffer.writeln('Platform(s): ${platforms is List ? platforms.join(', ') : platforms}');
      buffer.writeln('Content Type: $contentType');
      buffer.writeln('Topic/Theme: $topic');
      buffer.writeln('Post Time: $postTime');
      buffer.writeln('Caption: $caption');
      buffer.writeln('Hashtags: ${hashtags is List ? hashtags.join(' ') : hashtags}');
      buffer.writeln('');
    }

    return buffer.toString();
  }
}
