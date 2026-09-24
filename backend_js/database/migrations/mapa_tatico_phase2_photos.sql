-- Fase 2: galeria de fotos por ponto (até 10)

CREATE TABLE IF NOT EXISTS map_point_photos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    point_id INT NOT NULL,
    url VARCHAR(500) NOT NULL,
    caption VARCHAR(255) NULL,
    order_index INT NOT NULL DEFAULT 0,
    uploaded_by INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (point_id) REFERENCES map_points(id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by) REFERENCES policiais(id),
    INDEX idx_point_order (point_id, order_index)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO map_point_photos (point_id, url, order_index, uploaded_by)
SELECT id, photo_url, 0, creator_id
FROM map_points
WHERE photo_url IS NOT NULL AND photo_url != '';
