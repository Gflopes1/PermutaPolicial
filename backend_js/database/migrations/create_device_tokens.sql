-- Tokens FCM para push notifications (Android/iOS)

CREATE TABLE IF NOT EXISTS `device_tokens` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `policial_id` INT NOT NULL,
  `token` VARCHAR(512) NOT NULL,
  `platform` ENUM('android', 'ios', 'web') NOT NULL DEFAULT 'android',
  `criado_em` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  `atualizado_em` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_token` (`token`),
  KEY `idx_policial_id` (`policial_id`),
  CONSTRAINT `fk_device_tokens_policial`
    FOREIGN KEY (`policial_id`) REFERENCES `policiais` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
