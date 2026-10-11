# Resgate do Serjo — como jogar

Abra `project.godot` na Godot 4.7.2, pressione F5 e clique em **Jogar**. É single-player para PC.

Para jogar sem abrir o editor, extraia `builds/ResgateDoSerjo-Windows.zip` e abra `windows/JOGAR.cmd`. Mantenha todos os arquivos da pasta juntos. Esse pacote portátil inclui o executável local da Godot e o pacote do jogo.

## Controles

- WASD: andar; Shift: correr; mouse: olhar.
- F: ligar ou desligar a lanterna.
- E: libertar o Serjo, perto da porta da cela e com as 7 bolas.
- Esc: pausar ou continuar. O relógio, a proteção e os inimigos param durante a pausa.
- R: reiniciar a partida; F11: alternar tela cheia.

## Regras implementadas

- Partida de 5 minutos, 3 vidas e 7 bolas sorteadas entre 16 pontos do labirinto.
- Cada bola deixa o Josias mais rápido e aumenta sua luz vermelha. Ele segue os caminhos do mapa.
- Encostar no Josias tira uma vida, espalha todas as bolas e dispara "VIU AI FESO" em texto e voz sintetizada. São 2 segundos de proteção para fugir.
- Na sexta bola, o Ruan aparece com a imagem das torres e começa a perseguir. A entrada acontece uma vez por partida.
- Ruan não tira vida: rouba até 2 bolas, leva o jogador para um ponto livre perto do Josias e o atordoa por 3,5 segundos. As bolas perdidas voltam ao mapa. O Ruan espera 8 segundos para capturar novamente.
- Juntar 7 bolas libera o resgate, mas é necessário chegar à cela verde e apertar E. A porta abre e Serjo sai.
- A terceira captura mostra o Josias acertando uma cesta e encerra a partida.
- Se o tempo acabar, aparece o final de decepção do Serjo, contado em texto, sem cena gráfica.
- Menu principal, instruções, volume, pausa, reinício e finais de vitória/derrota.

O Serjo tem um modelo simples feito com formas 3D. Fat fica no começo dando a dica do objetivo. Josias e Ruan usam os modelos e fotos existentes. Os passos, a ambientação e os efeitos foram sintetizados; a fala usa uma voz do Windows, sem imitar a voz real do Josias. Os movimentos dos inimigos são procedurais.

## Onde editar

- `scenes/main.tscn`: labirinto, luzes e pontos de aparecimento. Algumas passagens foram ampliadas para conectar as áreas do mapa.
- `scripts/main.gd`: estados da partida, tempo, bolas, Ruan, resgate e finais. `round_seconds` pode ser ajustado no Inspetor do Main.
- `scripts/player.gd`: movimento, vida e proteção contra dano seguido.
- `scripts/killer.gd`: perseguição, raiva, contato e atordoamento do Josias.
- `scripts/ruan_enemy.gd`: captura do Ruan; reutiliza a navegação do Josias.
- `scripts/serjo_cage.gd`: cela e resgate; `scripts/basket_ending.gd`: cena da cesta.
- `scripts/game_ui.gd`: telas, mensagens e HUD.

Depois de mudar paredes, piso ou cela, rode na pasta do projeto:

```powershell
godot --headless --path . --script res://tools/bake_nav.gd
```

## Testes e pacote de Windows

Teste automático de navegação, regras, pausa, resgate e finais:

```powershell
godot --headless --path . --fixed-fps 60 --script res://tests/gameplay_test.gd
```

Para recriar o pacote portátil, informe o caminho do executável da Godot:

```powershell
./tools/build_windows.ps1 -GodotPath 'C:/caminho/Godot.exe'
```

Também existe um preset **Windows Desktop** para exportação normal pelo editor, após instalar os templates de exportação da mesma versão da Godot. O ZIP portátil usa a engine local porque os templates não estavam instalados.

As pastas `.godot/`, `builds/` e `artifacts/` não vão para o Git. O código, os modelos, as texturas, o áudio e o preset de exportação ficam no repositório.
