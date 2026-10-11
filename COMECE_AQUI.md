# Resgate do Serjo

Abra `project.godot` na Godot e pressione F5 para jogar. O projeto usa Godot 4.

## Controles

- WASD: andar; Shift: correr; mouse: olhar.
- F: ligar/desligar a lanterna.
- Esc: liberar/capturar o mouse; clique esquerdo: capturar novamente.
- R: reiniciar a partida.

## Estado atual

Sete bolas aparecem em pontos sorteados do labirinto. Na sexta coleta, o Ruan aparece e a imagem de entrada é exibida. O Josias começa no sul do mapa e já inicia a caçada, seguindo os corredores até o jogador. A captura, a perda das bolas e as condições de vitória e derrota ainda precisam ser implementadas.

## Onde mexer

- `scenes/main.tscn`: mapa, pontos de aparecimento das bolas e do Josias.
- `scripts/main.gd`: sorteio das bolas, contador e entrada do Ruan.
- `scenes/josias_mosntro.tscn` e `scripts/killer.gd`: visual, colisão e perseguição do Josias.
- `scenes/player.tscn` e `scripts/player.gd`: jogador, câmera, lanterna e controles.
- `navigation/labyrinth_navmesh.tres`: caminhos usados pelo Josias.

Depois de mudar paredes ou piso, gere novamente a malha de navegação com `godot --headless --path . --script res://tools/bake_nav.gd` na pasta do projeto. Confira também se cada marcador de `BallSpawns` continua acessível. Não versionem a pasta `.godot/`.
