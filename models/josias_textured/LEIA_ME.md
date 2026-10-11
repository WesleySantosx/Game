# Josias texturizado

Arraste `scenes/josias.tscn` para a cena do mapa na Godot.
Para ver frente e costas, abra `scenes/josias_preview.tscn` e aperte F6.

O visual tem o rosto da foto de referencia esticado na cabeca em losango,
regata azul e calcao preto. O material usa visual sem iluminacao para manter
a foto legivel e as cores chapadas do estilo zoado pedido.

- `josias_albedo.png`: textura do corpo inteiro, 2048 x 2048, frente e costas separadas.
- `josias_face.png`: rosto preparado a partir da foto pelo gerador de imagens integrado.
- `josias_mesh.tres`: malha com novo mapeamento UV, centralizada e com 1,85 m de altura.
- `josias_material.tres`: material que aponta para a textura PNG.
- `josias_textured.glb`: modelo portatil com textura embutida; pode abrir na Godot ou Blender.
- `josias_preview.png`: imagem de verificacao do modelo na Godot.

A textura do corpo usa o NOVO UV da malha entregue. Colocar o PNG direto no FBX
original nao produz o mesmo resultado. Use a cena pronta ou o GLB.

Esta entrega e so o visual: ainda nao tem IA, colisao ou animacoes.

Prompt usado no gerador integrado (resumo): rosto reconhecivel da foto de referencia,
sorriso e cabelo preservados, albedo quadrado frontal, fundo cor de pele, recorte
sem roupa nem fundo original, estilo foto colada e esticada de jogo amador.
A roupa e o atlas final foram aplicados por material e renderizados na Godot.
