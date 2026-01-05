import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            title: 'Startpage AppBar Icons',
            children: [
              _buildIconRow(
                icon: Icons.bluetooth,
                iconColor: Colors.grey,
                title: 'Bluetooth',
                description: 'Opens Bluetooth dialog to connect CW keyer.',
                colors: 'Grey = disconnected, Green = connected',
              ),
              _buildIconRow(
                icon: Icons.access_time,
                iconColor: Colors.green,
                title: 'Date/Time',
                description:
                    'Toggle hide/show date & time fields in the QSO form.',
                colors: 'Green = visible, Red = hidden',
              ),
              _buildIconRow(
                icon: Icons.emoji_events,
                iconColor: Colors.grey,
                title: 'Contest Mode',
                description:
                    'Toggle contest mode for faster logging. Hide unneded in the form.',
                colors: 'Grey = off, Green = on',
              ),
              _buildIconRow(
                icon: Icons.tag,
                iconColor: Colors.grey,
                title: 'Serial Number (NR)',
                description:
                    'Toggle serial number counter for QSOs. When enabled, automatically increments after each saved QSO.',
                colors: 'Grey = off, Green = on',
              ),
              _buildIconRow(
                icon: Icons.keyboard,
                iconColor: Colors.grey,
                title: 'Custom Keyboard',
                description: 'Toggle custom CW keyboard optimized for logging.',
                colors: 'Grey = off, Green = on',
              ),
              _buildIconRow(
                icon: Icons.dark_mode,
                iconColor: Colors.grey,
                title: 'Theme',
                description: 'Toggle between light and dark theme.',
                colors: 'Icon changes based on current theme',
              ),
              _buildIconRow(
                icon: Icons.coffee,
                iconColor: Colors.grey,
                title: 'Stay Awake',
                description: 'Prevent screen from sleeping during operation.',
                colors: 'Grey = off, Green = on',
              ),
              _buildIconRow(
                icon: Icons.schedule,
                iconColor: Colors.grey,
                title: 'UTC Time',
                description: 'Displays current UTC time (text, not tappable).',
                colors: null,
              ),
              _buildIconRow(
                icon: Icons.wifi,
                iconColor: Colors.grey,
                title: 'Internet Status',
                description: 'Shows current internet connection status.',
                colors: 'WiFi icon = connected, WiFi-off = disconnected',
              ),
            ],
          ),
          _buildSection(
            context,
            title: 'Info Text Line',
            children: [
              _buildTextRow(
                title: 'CW Exchange Preview',
                description:
                    'Displays the formatted CW exchange text that will be sent. '
                    'Shows: {CALLSIGN} {PRE} {RST} {NR} {ACTIVATION} {POST} {BK}',
              ),
              _buildTextRow(
                title: 'CALLSIGN',
                description:
                    'The other station\'s callsign from the input field.',
              ),
              _buildTextRow(
                title: 'PRE',
                description:
                    'Custom prefix text (e.g., "TU" or "R"). Configurable via settings icon.',
              ),
              _buildTextRow(
                title: 'RST',
                description:
                    'Signal report. With "9=N" option enabled, 9s are shown as N (e.g., 599 → 5NN).',
              ),
              _buildTextRow(
                title: 'NR',
                description:
                    'Serial number (when NR checkbox enabled). With "0=T" option, 0s are shown as T.',
              ),
              _buildTextRow(
                title: 'ACTIVATION',
                description:
                    'POTA/IOTA/SOTA reference if an activation is selected (e.g., "POTA DA0001").',
              ),
              _buildTextRow(
                title: 'POST',
                description:
                    'Custom suffix text (e.g., "73" or "GL"). Configurable via settings icon.',
              ),
              _buildTextRow(
                title: 'BK',
                description:
                    'Break signal appended when "Send BK" option is enabled.',
              ),
              _buildTextRow(
                title: 'Settings Icon',
                description:
                    'Tap the gear icon to customize colors, 9=N, 0=T, and show reference prefix options.',
              ),
            ],
          ),
          _buildSection(
            context,
            title: 'CW Buttons',
            children: [
              _buildButtonRow(
                label: 'CQ',
                color: Colors.green,
                description:
                    'Send CQ call via Bluetooth keyer. Text is customizable in settings.',
              ),
              _buildButtonRow(
                label: 'MY',
                color: Colors.grey,
                description:
                    'Send your own callsign (selected in callsign dropdown).',
              ),
              _buildButtonRow(
                label: 'CALL?',
                color: Colors.blueGrey,
                description:
                    'Send the other station\'s callsign (from callsign input field).',
              ),
              _buildButtonRow(
                label: 'RPT#',
                color: Colors.cyan,
                description:
                    'Send RST report only. Uses 9=N substitution if enabled.',
              ),
              _buildButtonRow(
                label: 'CUSTOM',
                color: Colors.purple,
                description:
                    'Send custom CW text. Only visible when custom text is configured.',
              ),
              _buildButtonRow(
                label: 'SEND',
                color: Colors.deepOrangeAccent,
                description:
                    'Send complete exchange: callsign + RST + serial number + activation reference.',
              ),
              _buildButtonRow(
                label: 'CLR',
                color: Colors.red,
                description: 'Clear all form fields and reset for next QSO.',
              ),
              _buildButtonRow(
                label: 'SAVE',
                color: Colors.blue,
                description:
                    'Save QSO to database and upload to enabled services (ClubLog, eQSL, LoTW).',
              ),
              _buildTextRow(
                title: 'Note',
                description:
                    'CW buttons (CQ, MY, CALL?, RPT#, CUSTOM, SEND) are only visible when mode is CW and Bluetooth keyer is connected.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildIconRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    String? colors,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                if (colors != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    colors,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextRow({required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonRow({
    required String label,
    required Color color,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
