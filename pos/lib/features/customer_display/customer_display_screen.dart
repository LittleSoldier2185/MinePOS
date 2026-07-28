import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/services/server_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatting.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../cashier/models/order_item.dart';
import '../cashier/services/menu_service.dart';
import '../cashier/services/order_service.dart';
import '../manager/services/shop_config_service.dart';
import '../welcome/welcome_screen.dart';
import 'services/customer_display_service.dart';

/// Full-screen, kiosk-style view meant for a second monitor/device facing
/// the customer. Purely passive — it never calls the server directly,
/// it just mirrors whatever the cashier's register publishes over
/// `/ws/customer-display`.
class CustomerDisplayScreen extends StatefulWidget {
  const CustomerDisplayScreen({super.key});

  @override
  State<CustomerDisplayScreen> createState() => _CustomerDisplayScreenState();
}

class _CustomerDisplayScreenState extends State<CustomerDisplayScreen> {
  final _svc = CustomerDisplayService.instance;

  @override
  void initState() {
    super.initState();
    _svc.addListener(_onChange);
    _svc.connect();
  }

  @override
  void dispose() {
    _svc.removeListener(_onChange);
    _svc.disconnect();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmExit() async {
    final ok = await confirmDialog(
      context,
      title: AppLocalizations.of(context)!.exitCustomerDisplayTitle,
      content: AppLocalizations.of(context)!.exitCustomerDisplayContent,
      confirmLabel: AppLocalizations.of(context)!.exitButton,
      cancelLabel: AppLocalizations.of(context)!.cancel,
      destructive: false,
    );
    if (ok && mounted) {
      MenuService.instance.reset();
      OrderService.instance.reset();
      ShopConfigService.instance.reset();
      ServerClient.instance.clear();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildBody()),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white24, size: 20),
                onPressed: _confirmExit,
              ),
            ),
            Positioned(
              top: 12,
              right: 16,
              child: _ConnectionDot(state: _svc.connectionState),
            ),
            if (_svc.selectedStation != null)
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => _svc.selectStation(null),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tv_outlined, size: 12, color: Colors.white38),
                        const SizedBox(width: 4),
                        Text(_svc.selectedStation!,
                            style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_svc.selectedStation == null) {
      return _StationPickerView(svc: _svc);
    }
    switch (_svc.state) {
      case CustomerDisplayState.cart:
        return _CartView(svc: _svc, baht: baht);
      case CustomerDisplayState.promptpay:
        return _PromptPayView(svc: _svc, baht: baht);
      case CustomerDisplayState.thankYou:
        return _ThankYouView(svc: _svc, baht: baht);
      case CustomerDisplayState.idle:
        // Ads only play while actively connected — a dropped connection
        // falls back to the plain idle screen instead of looping slides
        // that reference a server that might no longer be reachable.
        final canShowAds = _svc.connectionState == CustomerDisplayConnectionState.connected &&
            _svc.adSlides.isNotEmpty;
        return canShowAds ? _AdSlideshowView(svc: _svc) : const _IdleView();
    }
  }
}

class _StationPickerView extends StatelessWidget {
  const _StationPickerView({required this.svc});
  final CustomerDisplayService svc;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tv_outlined, color: AppColors.primaryLight, size: 56),
            const SizedBox(height: 20),
            Text(
              l10n.selectStationTitle,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            if (svc.stations.isEmpty)
              Text(
                l10n.noStationsOnlineMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              )
            else
              ...svc.stations.map(
                (s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: SizedBox(
                    width: 260,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => svc.selectStation(s),
                      child: Text(s, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IdleView extends StatelessWidget {
  const _IdleView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_cafe, color: AppColors.accent, size: 44),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.welcomeToMinePosMessage,
            style: const TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.orderWillAppearMessage,
            style: const TextStyle(color: Colors.white54, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

/// Idle-time advertising slideshow — cycles through `svc.adSlides` in order,
/// looping back to the start. Image/GIF slides advance after their own
/// configured duration; video slides advance when playback reaches the end.
class _AdSlideshowView extends StatefulWidget {
  const _AdSlideshowView({required this.svc});
  final CustomerDisplayService svc;

  @override
  State<_AdSlideshowView> createState() => _AdSlideshowViewState();
}

class _AdSlideshowViewState extends State<_AdSlideshowView> {
  int _index = 0;
  Timer? _timer;
  Player? _player;
  VideoController? _controller;
  StreamSubscription<bool>? _completedSub;

  @override
  void initState() {
    super.initState();
    _playCurrentSlide();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _completedSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  String _fullUrl(String relativeUrl) => 'http://${ServerClient.instance.baseUrl}$relativeUrl';

  void _playCurrentSlide() {
    _timer?.cancel();
    _completedSub?.cancel();
    _player?.dispose();
    _player = null;
    _controller = null;

    final slides = widget.svc.adSlides;
    if (slides.isEmpty) return;
    final slide = slides[_index % slides.length];

    if (slide.type == 'video') {
      final player = Player();
      final controller = VideoController(player);
      _player = player;
      _controller = controller;
      player.setVolume(slide.muted ? 0 : 100);
      player.open(Media(_fullUrl(slide.url)));
      _completedSub = player.stream.completed.listen((done) {
        if (done) _advance();
      });
    } else {
      _timer = Timer(Duration(seconds: slide.durationSeconds ?? 8), _advance);
    }
  }

  void _advance() {
    if (!mounted) return;
    final slides = widget.svc.adSlides;
    if (slides.isEmpty) return;
    setState(() {
      _index = (_index + 1) % slides.length;
      _playCurrentSlide();
    });
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.svc.adSlides;
    if (slides.isEmpty) return const _IdleView();
    final slide = slides[_index % slides.length];

    // BoxFit.contain (not .cover) so the whole slide is always visible —
    // letterboxed against the screen's dark background instead of cropped —
    // regardless of the slide's own resolution/aspect ratio vs the display's.
    return SizedBox.expand(
      child: slide.type == 'video' && _controller != null
          ? Video(controller: _controller!, fit: BoxFit.contain, controls: NoVideoControls)
          : Image.network(_fullUrl(slide.url), fit: BoxFit.contain),
    );
  }
}

class _CartView extends StatelessWidget {
  const _CartView({required this.svc, required this.baht});
  final CustomerDisplayService svc;
  final String Function(double) baht;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 40, 32, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                svc.orderNumber.isEmpty
                    ? AppLocalizations.of(context)!.customerDisplayOrderLabel
                    : AppLocalizations.of(context)!
                        .customerDisplayOrderWithNumber(svc.orderNumber),
                style: const TextStyle(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
              ),
              Text(
                AppLocalizations.of(context)!.itemsCount(
                    svc.items.fold<int>(0, (s, i) => s + i.quantity)),
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            itemCount: svc.items.length,
            separatorBuilder: (_, _) => const Divider(color: Colors.white12, height: 1),
            itemBuilder: (context, index) {
              final item = svc.items[index];
              final name = item.menuItem.displayName(Localizations.localeOf(context));
              final label = item.sweetness == null
                  ? name
                  : '$name (${item.sweetness!.label(AppLocalizations.of(context)!)})';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    Text('${item.quantity}×',
                        style: const TextStyle(color: Colors.white54, fontSize: 18)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(label,
                          style: const TextStyle(color: Colors.white, fontSize: 18)),
                    ),
                    Text(baht(item.subtotal),
                        style: const TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (svc.discountTotal > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        svc.promotionNames.join(', '),
                        style: const TextStyle(color: AppColors.primaryLight, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text('-${baht(svc.discountTotal)}',
                        style: const TextStyle(color: AppColors.primaryLight, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppLocalizations.of(context)!.total,
                      style: const TextStyle(color: Colors.white70, fontSize: 20)),
                  Text(
                    baht(svc.total),
                    style: const TextStyle(
                        color: AppColors.primaryLight, fontSize: 34, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PromptPayView extends StatelessWidget {
  const _PromptPayView({required this.svc, required this.baht});
  final CustomerDisplayService svc;
  final String Function(double) baht;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            svc.orderNumber.isEmpty
                ? l10n.customerDisplayOrderLabel
                : l10n.customerDisplayOrderWithNumber(svc.orderNumber),
            style: const TextStyle(
                color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Container(
            width: 220,
            height: 220,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImageView(data: svc.promptPayPayload),
          ),
          if (svc.promptPayLabel.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              svc.promptPayLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            baht(svc.total),
            style: const TextStyle(
                color: AppColors.primaryLight, fontSize: 34, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.scanQrToPayMessage,
            style: const TextStyle(color: Colors.white54, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _ThankYouView extends StatelessWidget {
  const _ThankYouView({required this.svc, required this.baht});
  final CustomerDisplayService svc;
  final String Function(double) baht;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: AppColors.primaryLight, size: 84),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.thankYouMessage,
            style: const TextStyle(
                color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
              AppLocalizations.of(context)!
                  .totalPaidLabel(baht(svc.thankYouTotal)),
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          if (svc.thankYouChange > 0) ...[
            const SizedBox(height: 4),
            Text(
                AppLocalizations.of(context)!
                    .changeMessageLabel(baht(svc.thankYouChange)),
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ],
      ),
    );
  }
}

class _ConnectionDot extends StatelessWidget {
  const _ConnectionDot({required this.state});
  final CustomerDisplayConnectionState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      CustomerDisplayConnectionState.connected => Colors.green,
      CustomerDisplayConnectionState.connecting => Colors.amber,
      CustomerDisplayConnectionState.error => AppColors.terracottaDark,
      CustomerDisplayConnectionState.disconnected => Colors.white24,
    };
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
