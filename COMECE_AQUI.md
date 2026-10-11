# Primeiro prototipo

Abra `project.godot` na Godot e pressione F6 com `scenes/main.tscn` aberta, ou F5 para executar o projeto.

## Controles

- WASD: andar.
- Mouse: olhar.
- Shift: correr.
- F: ligar/desligar lanterna.
- Esc: liberar/capturar mouse (nao pausa a partida).
- Clique esquerdo: capturar mouse novamente.
- R: reiniciar a sala.

## O que testar

1. Ande pela sala e tente atravessar as paredes: a colisao deve impedir.
2. Mire a lanterna nas paredes e desligue com F.
3. Encoste na bola laranja: ela desaparece e o contador muda para 1/7.
4. Aperte R: a bola volta e o contador zera.

## Onde mexer

- `scenes/main.tscn`: sala de teste, luzes e posicoes do jogador e bola. Edite pela aba 3D.
- `scenes/player.tscn`: colisao, camera e lanterna do jogador.
- `scripts/player.gd`: movimento e controles. Velocidades aparecem no Inspetor do Player.
- `scenes/ball.tscn`: visual e area de coleta da bola (modelo provisório).
- `scripts/ball.gd`: animacao e aviso de coleta.
- `scripts/main.gd`: contador da partida e reinicio.

Esta etapa tem uma unica bola para aprender e testar a base. Ainda faltam as outras seis, o labirinto, Serjo, Josias, Ruan, tempo e finais.

Proximo marco: espalhar sete bolas e centralizar a contagem num controlador da partida. Depois adicionar as regras de captura e os inimigos.

Os arquivos ficam locais ate voces fazerem commit e push. Nao versionem a pasta `.godot/`.
