# Fat, Ruan e torres

- `scenes/fat.tscn`: modelo Fat com regata preta, calcao preto e termica escura nas pernas, por baixo do calcao. Sem foto de rosto para o Fat, foi mantida uma cara simples no modelo.
- `scenes/ruan.tscn`: personagem do arquivo Sem titulo, roupa preta e rosto baseado na foto fornecida.
- `scenes/ruan_towers.tscn`: duas torres extraidas do mesmo FBX, separadas do personagem, com material de janelas.
- `scenes/fat_ruan_preview.tscn`: abra na Godot e aperte F6 para conferir os tres modelos.
- `scenes/ruan_intro.tscn`: imagem de impacto nas torres com entrada e saida suave, 2,5 segundos de duracao.
- `models/fat_textured.glb` e `models/ruan_textured/ruan_textured.glb`: modelos portateis com materiais.

Na sexta bola, o script main.gd coloca o Ruan num ponto livre longe do jogador e mostra a imagem das torres. Por enquanto o Ruan e apenas um modelo estatico; perseguicao e captura ainda nao foram implementadas. R reinicia a partida e permite testar novamente.

Os modelos estao centralizados, com os pes no chao, altura aproximada de 1,85 m e frente voltada para -Z. Ainda nao possuem animacoes nem colisoes de inimigo.

O gerador de imagens integrado foi usado para:

1. Rosto frontal do Ruan: preservar a identidade da foto, cabelo e expressao; retirar telefone, mao e fundo; imagem quadrada com fundo cor de pele, estilo foto colada de jogo amador.
2. Imagem das torres: arte 16:9 de jogo retro, duas torres, aviao em silhueta, clarão de impacto e fumaca, noite azul-escura, sem texto nem pessoas.

A roupa foi aplicada com materiais e cores da malha na Godot. As torres usam o shader `tower_windows.gdshader`. A imagem de impacto e uma ilustracao estatica, exibida com fade, nao um video.
