import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/snackbar_utils.dart';

class AdminStructureScreen extends StatefulWidget {
  const AdminStructureScreen({super.key});

  @override
  State<AdminStructureScreen> createState() => _AdminStructureScreenState();
}

class _AdminStructureScreenState extends State<AdminStructureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _programs = [];
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final programs = await Supabase.instance.client
          .from('programs')
          .select('*, branches(*, batches(*, sections(*)))')
          .order('name');
      final subjects = await Supabase.instance.client
          .from('subjects')
          .select()
          .order('code');
      if (mounted) {
        setState(() {
          _programs = (programs as List).cast<Map<String, dynamic>>();
          _subjects = (subjects as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to load: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addProgram() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Program'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Program Name (e.g. B.Tech)'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              TextFormField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Code (e.g. BTECH)'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await Supabase.instance.client.from('programs').insert({
                  'name': nameCtrl.text.trim(),
                  'code': codeCtrl.text.trim().toUpperCase(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
                if (mounted) SnackbarUtils.showSuccess(context, 'Program added');
              } catch (e) {
                if (mounted) SnackbarUtils.showError(context, 'Failed: $e');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSubject() async {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final creditsCtrl = TextEditingController(text: '3');
    final formKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Subject'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Subject Name'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              TextFormField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Code'),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              TextFormField(
                controller: creditsCtrl,
                decoration: const InputDecoration(labelText: 'Credits'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await Supabase.instance.client.from('subjects').insert({
                  'name': nameCtrl.text.trim(),
                  'code': codeCtrl.text.trim().toUpperCase(),
                  'credits': int.tryParse(creditsCtrl.text.trim()) ?? 3,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
                if (mounted) SnackbarUtils.showSuccess(context, 'Subject added');
              } catch (e) {
                if (mounted) SnackbarUtils.showError(context, 'Failed: $e');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Structure'),
        leading: BackButton(onPressed: () => context.go('/admin')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Programs & Branches'),
            Tab(text: 'Subjects'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _addProgram();
          } else {
            _addSubject();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                ListView.builder(
                  itemCount: _programs.length,
                  itemBuilder: (context, index) {
                    final p = _programs[index];
                    final branches = (p['branches'] as List? ?? []).cast<Map<String, dynamic>>();
                    return ExpansionTile(
                      title: Text('${p['name']} (${p['code']})'),
                      subtitle: Text('${branches.length} branches'),
                      children: [
                        for (final b in branches)
                          Padding(
                            padding: const EdgeInsets.only(left: 16),
                            child: ExpansionTile(
                              title: Text('${b['name']} (${b['code']})'),
                              children: [
                                for (final batch in (b['batches'] as List? ?? []))
                                  Padding(
                                    padding: const EdgeInsets.only(left: 32),
                                    child: ListTile(
                                      title: Text('Batch ${batch['name']}'),
                                      subtitle: Text(
                                        'Sections: ${((batch['sections'] as List?) ?? []).map((s) => s['name']).join(', ')}',
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                ),
                ListView.builder(
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final s = _subjects[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.accentColor,
                        child: Text(
                          s['code']?.toString().substring(0, 2) ?? 'S',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      title: Text(s['name'] ?? ''),
                      subtitle: Text('Code: ${s['code']} | Credits: ${s['credits']}'),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
