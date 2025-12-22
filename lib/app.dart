import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/scanner/presentation/bloc/scanner_bloc.dart';
import 'features/product/presentation/bloc/product_bloc.dart';
import 'features/carcinogen/presentation/bloc/carcinogen_bloc.dart';
import 'features/history/presentation/bloc/history_bloc.dart';
import 'features/history/presentation/bloc/history_event.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/product/presentation/pages/product_result_page.dart';
import 'injection_container.dart';

class YukoApp extends StatelessWidget {
  const YukoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ScannerBloc>()),
        BlocProvider(create: (_) => sl<ProductBloc>()),
        BlocProvider(create: (_) => sl<CarcinogenBloc>()),
        BlocProvider(create: (_) => sl<HistoryBloc>()..add(const LoadHistoryEvent())),
      ],
      child: MaterialApp(
        title: 'Yuko',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/product':
              final barcode = settings.arguments as String;
              return MaterialPageRoute(
                builder: (_) => ProductResultPage(barcode: barcode),
              );
            default:
              return MaterialPageRoute(
                builder: (_) => const HomePage(),
              );
          }
        },
      ),
    );
  }
}