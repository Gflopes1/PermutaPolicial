  -- Foto de perfil do policial (URL na CDN)
  ALTER TABLE policiais
    ADD COLUMN foto_perfil VARCHAR(1024) NULL DEFAULT NULL AFTER nome;
