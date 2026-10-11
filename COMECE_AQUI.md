# Resgate do Serjo — como jogar

Abra `project.godot` na Godot 4.7.2, pressione F5 e clique em **Jogar**. É single-player para PC.

Para jogar sem abrir o editor, extraia `builds/ResgateDoSerjo-Windows.zip` e abra `windows/JOGAR.cmd`. Mantenha todos os arquivos da pasta juntos. Esse pacote portátil inclui o executável local da Godot e o pacote do jogo.

## Controles

- WASD: andar; Shift: correr; mouse: olhar.
- F: ligar ou desligar a lanterna.
- E: pegar melhoria, conversar com Fat ou libertar o Serjo com as 7 bolas.
- 1 / 2: substituir uma melhoria quando os dois espaços estão ocupados. A antiga fica no chão.
- Q: usar a mão do Adrian; clique esquerdo: disparar a arma do Fat.
- Espaço: acertar a faixa verde nos desafios do Fat ou na fuga do Ruan.
- Perto do Fat, E abre a conversa; G tenta conseguir a arma e T troca bolas por vida.
- Esc: pausar ou continuar. O relógio, a proteção e os inimigos param durante a pausa.
- R: reiniciar a partida; F11: alternar tela cheia.

## Regras implementadas

- Partida de 5 minutos, 3 vidas e 7 bolas sorteadas entre 16 pontos do labirinto.
- Cada bola deixa o Josias mais rápido e aumenta sua luz vermelha. Ele segue os caminhos do mapa.
- Encostar no Josias tira uma vida, dá um susto e dispara "VIU AI FESO" em texto e voz sintetizada. Na primeira pancada perde metade das bolas, arredondada para baixo (uma bola perde uma). Da segunda em diante perde todas. São 2 segundos de proteção para fugir.
- Na sexta bola, o Ruan aparece com a imagem das torres e começa a perseguir. A entrada acontece uma vez por partida.
- Ruan dá um susto e carrega o jogador pelos corredores até Josias; seu modelo aparece ao lado da câmera. Três acertos na faixa verde com Espaço soltam você sem perder bolas. Errar remove um acerto, sem deixar o progresso negativo.
- Durante o transporte não pode andar, coletar bolas, disparar ou receber dano; pode olhar e tentar escapar. O relógio continua. A entrega só acontece depois de 7 segundos; se Ruan não chegar ao Josias em 18 segundos, você se solta automaticamente para evitar ficar preso na navegação.
- Se for entregue, perde até 2 bolas e Josias fica atordoado por 3,5 segundos. Você recebe proteção pelo mesmo tempo e Ruan espera 8 segundos. Se escapar, Ruan fica atordoado por 6 segundos e você ganha 2,5 segundos de proteção.
- Juntar 7 bolas libera o resgate, mas é necessário chegar à cela verde e apertar E. A porta abre e Serjo sai.
- Quando acabam as vidas, Josias acerta uma cesta e a partida termina. A vida extra do Fat permite sobreviver a mais uma pancada.
- Se o tempo acabar, aparece o final de decepção do Serjo, contado em texto, sem cena gráfica.
- Menu principal, instruções, volume, pausa, reinício e finais de vitória/derrota.

## Melhorias e equilíbrio

Três objetos iluminados aparecem em pontos acessíveis diferentes do mapa. Você equipa até dois; a arma tem espaço separado. A troca de uma melhoria deixa a anterior no chão. As melhorias continuam equipadas depois de levar dano.

| Objeto | Efeito |
| --- | --- |
| Tênis do Fabricio | Corrida 18% mais rápida (6 → 7,08 m/s). |
| Pulmão do Wesley | Stamina recupera 34/s em vez de 20/s; espera antes de recuperar cai de 0,9s para 0,4s. |
| Mão do Adrian | Q revela uma bola aleatória por 6s, através das paredes, com direção e distância no HUD. Recarga de 45s. |

A stamina tem 100 pontos: correr consome 20/s, dando cinco segundos de corrida contínua. Ao esgotar, precisa recuperar 25 pontos para voltar a correr. A câmera abre um pouco durante a corrida; sons de tensão aceleram perto de Josias. O HUD mostra a stamina e o tempo restante de atordoamento dos inimigos.

Fat aceita cinco bolas em troca de uma vida extra **uma vez por partida**. As cinco voltam ao mapa; se tinha seis ou sete, mantém o restante. Não recupera o tempo gasto e não remove Ruan da partida.

Para a arma, há **70% de chance de oferta**, até duas tentativas por partida, com 45s entre elas. Uma oferta exige dois testes de arremesso seguidos. Errar ou sair de perto do Fat consome a chance; acertar os dois ganha a Arremessadora. Durante o desafio há proteção temporária de 5,5s, e o relógio continua.

A arma lança uma boneca-mulher estilizada: três disparos por partida, intervalo de 12s e alcance de 16m. Um acerto atordoa Josias por 4,5s. Paredes bloqueiam o tiro, errar gasta munição e a arma não causa dano nem afeta Ruan. Os tiros não são reabastecidos.

O Serjo, as melhorias e a arma têm modelos simples feitos com formas 3D. Josias, Fat e Ruan usam os modelos existentes. Os passos, a ambientação e os efeitos foram sintetizados; a fala usa uma voz do Windows, sem imitar a voz real do Josias. Os movimentos dos inimigos são procedurais.

## Onde editar

- `scenes/main.tscn`: labirinto, luzes e pontos de aparecimento. Algumas passagens foram ampliadas para conectar as áreas do mapa.
- `scripts/main.gd`: estados da partida, tempo, bolas, Ruan, resgate e finais. `round_seconds` pode ser ajustado no Inspetor do Main.
- `scripts/game_features.gd`: Fat, melhorias, arma, recargas, testes de habilidade e transporte. As constantes no começo ajustam chance e recargas.
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
godot --headless --path . --fixed-fps 60 --script res://tests/features_test.gd
```

Para recriar o pacote portátil, informe o caminho do executável da Godot:

```powershell
./tools/build_windows.ps1 -GodotPath 'C:/caminho/Godot.exe'
```

Também existe um preset **Windows Desktop** para exportação normal pelo editor, após instalar os templates de exportação da mesma versão da Godot. O ZIP portátil usa a engine local porque os templates não estavam instalados.

As pastas `.godot/`, `builds/` e `artifacts/` não vão para o Git. O código, os modelos, as texturas, o áudio e o preset de exportação ficam no repositório.
