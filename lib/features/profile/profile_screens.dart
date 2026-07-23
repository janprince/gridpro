import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:grid_professionals/core/theme/app_theme.dart';
import 'package:grid_professionals/core/utils/formatters.dart';
import 'package:grid_professionals/core/widgets/app_widgets.dart';
import 'package:grid_professionals/data/mock_data.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => AppPage(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Professional profile',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          IconButton(
            onPressed: () => context.push('/edit-profile'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      const SizedBox(height: 18),
      const Center(
        child: Stack(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.mint,
              child: Text(
                'KM',
                style: TextStyle(
                  color: AppColors.forest,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.teal,
                child: Icon(Icons.verified, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const Center(
        child: Text(
          'Kofi Mensah',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(height: 4),
      const Center(
        child: Text(
          'Mensah Electrical & Cooling',
          style: TextStyle(color: AppColors.muted),
        ),
      ),
      const SizedBox(height: 10),
      Center(
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: const [
            Chip(
              avatar: Icon(Icons.verified, size: 16),
              label: Text('GRID Verified*'),
            ),
            Chip(label: Text('Top Rated*')),
            Chip(label: Text('Preferred Pro*')),
          ],
        ),
      ),
      const SizedBox(height: 4),
      const Center(
        child: Text(
          '* Sample badges for this mocked profile',
          style: TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      ),
      const SizedBox(height: 18),
      const Row(
        children: [
          Expanded(
            child: _ProfileMetric(value: '4.9', label: 'Rating'),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _ProfileMetric(value: '124', label: 'Jobs'),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _ProfileMetric(value: '98%', label: 'Response'),
          ),
          SizedBox(width: 8),
          Expanded(
            child: _ProfileMetric(value: '96%', label: 'On time'),
          ),
        ],
      ),
      const SectionHeader('Services'),
      AppCard(
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ServiceImage.forCategory('Electrical', size: 40),
              title: const Text(
                'Electrical installations',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Wiring, fixtures, panel upgrades'),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ServiceImage.forCategory('AC Repair', size: 40),
              title: const Text(
                'AC repair & maintenance',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Diagnostics, cleaning and installation'),
            ),
          ],
        ),
      ),
      const SectionHeader('Service areas'),
      Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final area in MockData.professional.serviceAreas)
            Chip(label: Text(area)),
        ],
      ),
      SectionHeader(
        'Portfolio',
        action: 'View all',
        onAction: () => context.push('/portfolio'),
      ),
      _PortfolioPreview(onTap: () => context.push('/portfolio')),
      const SectionHeader('Professional growth'),
      SupportActionCard(
        icon: Icons.insights,
        title: 'Ratings & performance',
        subtitle: 'See scores and customer reviews.',
        onTap: () => context.push('/performance'),
      ),
      const SizedBox(height: 10),
      SupportActionCard(
        icon: Icons.school_outlined,
        title: 'Training & growth',
        subtitle: 'Build skills and earn future badges.',
        onTap: () => context.push('/training'),
      ),
    ],
  );
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 10),
        ),
      ],
    ),
  );
}

class _PortfolioPreview extends StatelessWidget {
  const _PortfolioPreview({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Row(
      children: [
        for (final item in MockData.portfolio.take(2))
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ServiceImage.assetForCategory(item.category) != null
                        ? Image.asset(
                            ServiceImage.assetForCategory(item.category)!,
                            height: 105,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            semanticLabel: item.category,
                          )
                        : Container(
                            height: 105,
                            color: Color(item.colorValue),
                            alignment: Alignment.center,
                            child: Text(
                              item.category[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit profile')),
    body: AppPage(
      children: [
        const Center(
          child: CircleAvatar(
            radius: 45,
            backgroundColor: AppColors.mint,
            child: Icon(Icons.add_a_photo_outlined, color: AppColors.forest),
          ),
        ),
        const SizedBox(height: 22),
        const TextField(
          decoration: InputDecoration(labelText: 'Full name'),
          controller: null,
        ),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Business name',
            hintText: 'Mensah Electrical & Cooling',
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Professional bio',
            hintText: 'Licensed electrical and AC professional...',
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Years of experience',
            hintText: '8',
          ),
        ),
        const SectionHeader('Service categories'),
        Wrap(
          spacing: 8,
          children: const [
            FilterChip(
              label: Text('Electrical'),
              selected: true,
              onSelected: null,
            ),
            FilterChip(
              label: Text('AC repair'),
              selected: true,
              onSelected: null,
            ),
            FilterChip(label: Text('Solar'), selected: false, onSelected: null),
          ],
        ),
        const SectionHeader('Areas served'),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final area in MockData.professional.serviceAreas)
              Chip(label: Text(area)),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => context.pop(),
          child: const Text('Save profile'),
        ),
      ],
    ),
  );
}

class PortfolioScreen extends StatelessWidget {
  const PortfolioScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Portfolio')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mock portfolio item added.')),
      ),
      icon: const Icon(Icons.add),
      label: const Text('Add project'),
    ),
    body: AppPage(
      children: [
        const Text(
          'Show customers the quality and range of your work.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        for (final item in MockData.portfolio)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(13),
                    ),
                    child: ServiceImage.assetForCategory(item.category) != null
                        ? Image.asset(
                            ServiceImage.assetForCategory(item.category)!,
                            height: 165,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            semanticLabel: item.category,
                          )
                        : Container(
                            height: 165,
                            color: Color(item.colorValue),
                            alignment: Alignment.center,
                            child: Text(
                              item.category[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Chip(label: Text(item.category)),
                        const SizedBox(height: 6),
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          item.notes,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ratings & performance')),
    body: AppPage(
      children: [
        const MetricCard(
          label: 'Overall customer rating',
          value: '4.9 / 5.0',
          icon: Icons.star,
          dark: true,
          caption: 'Based on 120 sample jobs',
        ),
        const SectionHeader('Performance scores'),
        const _Score(label: 'On-time score', value: .96),
        const _Score(label: 'Completion rate', value: .98),
        const _Score(label: 'Quote clarity', value: .93),
        const _Score(label: 'Response rate', value: .98),
        const _Score(label: 'Complaint-free rate', value: .99),
        const SectionHeader('Customer reviews'),
        for (final review in MockData.reviews)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          review.customer,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const Icon(
                        Icons.star,
                        size: 17,
                        color: AppColors.warning,
                      ),
                      Text(' ${review.rating}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(review.comment),
                  const SizedBox(height: 6),
                  Text(
                    formatDate(review.date),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const AppCard(
          color: AppColors.mint,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline, color: AppColors.forest),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Uploading clear completion photos and arriving on time can help you receive more jobs.',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Score extends StatelessWidget {
  const _Score({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text('${(value * 100).round()}%'),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value,
          minHeight: 7,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    ),
  );
}

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Training & growth')),
    body: AppPage(
      children: [
        const AppCard(
          color: AppColors.forest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.workspace_premium, color: Colors.white),
              SizedBox(height: 12),
              Text(
                'Grow your professional edge',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Mock modules prepare the structure for future certificates and badges.',
                style: TextStyle(color: AppColors.mint),
              ),
            ],
          ),
        ),
        const SectionHeader('Learning path'),
        for (final module in MockData.training)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.mint,
                    child: Icon(
                      module.progress == 1 ? Icons.check : Icons.play_arrow,
                      color: AppColors.forest,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${module.category} • ${module.durationMinutes} min',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: module.progress,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${(module.progress * 100).round()}%'),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
