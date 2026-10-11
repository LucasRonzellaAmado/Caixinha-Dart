import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String title, String subtitle, String route) =>
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(route),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Mais')),
      body: ListView(
        children: [
          item(Icons.people_outline, 'Clientes',
              'Quem te deve e há quanto tempo', AppRoutes.customers),
          item(Icons.speed, 'Limite do MEI',
              'Quanto já faturou no ano', AppRoutes.meiLimit),
          item(Icons.notifications_outlined, 'Lembretes',
              'DAS e declaração anual', AppRoutes.reminders),
          item(Icons.picture_as_pdf_outlined, 'Relatórios',
              'PDF e planilha para o contador', AppRoutes.reports),
          item(Icons.category_outlined, 'Categorias',
              'Organize entradas e saídas', AppRoutes.categories),
          item(Icons.settings_outlined, 'Configurações',
              'Negócio, Pix, aparência e backup', AppRoutes.settings),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Sobre o Caixinha'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Caixinha',
              applicationVersion: '1.0.0',
              applicationLegalese:
                  'Feito para MEIs e autônomos organizarem o dinheiro do negócio.',
            ),
          ),
        ],
      ),
    );
  }
}
