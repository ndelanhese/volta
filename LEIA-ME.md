# Volta

App gratuito e local para memorizar posição, tamanho e mesa do Mission Control das janelas,
com uma organização para cada conjunto de monitores. Copie Volta.app para Aplicativos antes de usar.

Prévia pública: Apple Silicon, macOS 27 ou mais recente; validada no macOS 27.0.1.
Download em [Releases](https://github.com/ndelanhese/volta/releases). Assinatura local, sem notarização Apple.

Interface disponível em inglês e português brasileiro. Por padrão segue idioma do macOS, com inglês
como alternativa para idiomas não suportados. Seletor **Language / Idioma** muda imediatamente entre
**Seguir macOS**, **English** e **Português (Brasil)** e salva preferência. Descrições de permissões do
sistema também possuem traduções; diálogos do macOS seguem idioma configurado no sistema.

## Primeiro uso

1. Abra Volta. Clique no ícone com três retângulos na barra de menus para mostrar controles.
2. Autorize **Acessibilidade**. A permissão opcional **Gravação da tela** permite identificar
   títulos de janelas nas outras mesas; Volta não grava imagens nem áudio.
3. Com monitores conectados, organize janelas e mesas. Clique **Memorizar agora**.
4. Desconecte monitores. Aguarde a mudança estabilizar, organize a tela do Mac e clique
   **Memorizar agora** novamente. Cada conjunto de telas mantém seu próprio registro.
5. Nas próximas conexões/desconexões, aguarde cerca de **10 segundos após a última mudança**.
   O motor espera o macOS terminar de reorganizar as telas antes de restaurar.

Enquanto ativo, Volta aprende alterações nas mesas visíveis a cada 5 segundos. Espere esse
intervalo antes de desconectar, ou use **Memorizar agora**. O primeiro uso de uma configuração
nova precisa dessa organização inicial.

**Restaurar organização** solicita retorno ao registro aprendido para as telas atuais.
**Pausar** permite deixar tudo como estiver. No menu `…`, **Abrir ao iniciar sessão** configura
início automático; essa opção fica desligada até ser selecionada.

## Dados e privacidade

Dados ficam somente em `~/Library/Application Support/Volta/`:

- `spacekeeper.db`: organizações e histórico por conjunto de monitores.
- `snapshots/`: pontos locais de recuperação, até 200 mais o mais completo.
- `watch.log`: funcionamento e falhas de restauração.
- `status.json`: permissões e estado do motor, sem títulos das janelas.

Histórico pode conter nomes de apps e títulos das janelas. Nenhum servidor, conta, telemetria
ou assinatura. REA, Node e Go não são necessários para executar app compilado.

## Limites

- Mesas comuns do Mission Control são o foco. Janelas nativas em tela cheia, pares Split View
  e janelas atribuídas a todas as mesas não têm a mesma garantia de reconstrução automática.
- Alguns apps recusam movimento ou tamanho via Acessibilidade. Falhas aparecem no histórico.
- Recriar mesas removidas pelo macOS abre Mission Control brevemente. Volta não exclui mesas.
- Movimento entre mesas usa API privada do macOS. Validado neste Mac com macOS 27.0.1;
  atualizações futuras podem exigir adaptação.
- Restaurar associação não reabre apps fechados nem recupera documentos.
- A recuperação manual de snapshots pela CLI original tem limites para tamanhos em mesas
  ocultas. Por isso a interface usa o motor automático, que prepara essas janelas antes de
  redimensioná-las, e não oferece restauração cega de snapshots antigos.

## Compilar

Requer Swift Command Line Tools e Go 1.26. Na pasta deste arquivo:

```bash
./build.sh
```

Produz `dist/build.noindex/Volta.app`, roda testes e verifica assinatura local. A pasta `build.noindex` evita indexar cópias de build na busca. Sem Xcode completo ou conta
Apple Developer. Desde beta.3, o build cria uma identidade local de assinatura permanente em
`~/Library/Application Support/Volta/Signing/`. Preserve essa pasta privada: contém o chaveiro
e sua senha, acessíveis apenas ao usuário. Não entra no app nem no Git. Nenhuma configuração
de confiança do sistema é alterada. O certificado vale dez anos; faça backup seguro da pasta.

A assinatura permanece igual entre recompilações. Migrar das versões antigas com assinatura
ad hoc ou trocar entre download e build próprio exige nova autorização uma vez. Se necessário,
remova a entrada antiga nos Ajustes e adicione `/Applications/Volta.app` novamente. Volta consulta
as permissões reais do macOS, sem salvar um falso estado de autorização.

Para atualizar, saia do app antes de substituir a cópia instalada. `VOLTA_SIGNING_DIR` permite
escolher outro caminho absoluto para a identidade. `VOLTA_ADHOC=1 ./build.sh` usa assinatura
descartável explicitamente; nesse modo, recompilar pode invalidar permissões.

Código do motor e licença MIT ficam em `Engine/`; alterações locais e origem em `THIRD-PARTY.md`.

## Remover

Desative início de sessão no menu `…`, escolha **Sair do Volta** e remova app de Aplicativos.
Os dados locais são preservados; podem ser removidos separadamente caso não sejam mais úteis.
