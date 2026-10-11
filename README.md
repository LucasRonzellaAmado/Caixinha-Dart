# Caixinha

App Flutter para MEIs e autônomos controlarem o dinheiro do negócio: lançamentos, separação pessoal × negócio, pró-labore, painel com gráficos, termômetro do limite MEI, lembretes do DAS e da DASN-SIMEI, cobrança Pix (BR Code com CRC16), clientes e contas a receber, relatórios PDF/CSV e backup local ou no seu próprio servidor.

## Requisitos

- Flutter 3.32+ (Dart 3.8+)
- Android SDK / JDK 17

## Rodando

```bash
flutter create . --org br.com.lucasamado --project-name caixinha --platforms=android,ios
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

O `flutter create .` só completa os arquivos de plataforma que faltam (gradlew, iOS) e não sobrescreve nada.

## Testes

```bash
flutter analyze
flutter test
flutter test integration_test
```

## Ícone e splash

Já vêm prontos para Android. Para regenerar em todas as plataformas:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Release (Play Store)

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
cp android/key.properties.example android/key.properties
flutter build appbundle --release
```

## Estrutura

```
lib/
  core/        banco (drift), regras fiscais, tema, rotas, widgets e utilitários
  features/
    transactions/  dashboard/  mei_limit/  reminders/  pix/
    customers/     reports/    settings/   onboarding/
      data/ domain/ presentation/
server/        API de backup em Go para o homelab
```

Regras fiscais (limite do MEI, vencimento do DAS, prazo da DASN, faixas do termômetro, feriados bancários) ficam em `lib/core/fiscal/fiscal_rules.dart`. O valor do limite usado pelo app é configurável nas Configurações.

## Servidor de backup (homelab)

```bash
cd server
export CAIXINHA_TOKENS="um-token-bem-grande-e-aleatorio"
mkdir -p data && sudo chown 65532:65532 data
docker compose up -d --build
```

Coloque atrás de um proxy com HTTPS (Caddy, Traefik ou Tailscale) e configure no app em Configurações → Servidor de backup.
