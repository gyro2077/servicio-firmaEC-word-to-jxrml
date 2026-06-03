package ec.edu.espe.gestion_publicaciones.firmaec.model.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@Entity
@Table(name = "firmas_electronicas", schema = "publicaciones",
       uniqueConstraints = @UniqueConstraint(
           columnNames = {"id_documento_firmable", "orden_firma"}))
public class FirmaElectronicaEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_firma_electronica")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_documento_firmable", nullable = false)
    private DocumentoFirmableEntity documentoFirmable;

    @Column(name = "orden_firma", nullable = false)
    private int ordenFirma;

    @Column(name = "cedula_firmante", nullable = false, length = 15)
    private String cedulaFirmante;

    @Column(name = "nombre_firmante", length = 200)
    private String nombreFirmante;

    @Column(name = "rol_firma", length = 100)
    private String rolFirma;

    @Column(name = "estado", nullable = false, length = 20)
    private String estado = "PENDIENTE";

    @Column(name = "fecha_firma")
    private LocalDateTime fechaFirma;

    @Column(name = "hash_firma", length = 256)
    private String hashFirma;

    @Column(name = "qr_base64", columnDefinition = "TEXT")
    private String qrBase64;

    @Column(name = "etiqueta_ancla", length = 10)
    private String etiquetaAncla;

    @Column(name = "coordenada_x")
    private Integer coordenadaX;

    @Column(name = "coordenada_y")
    private Integer coordenadaY;

    @Column(name = "pagina_firma")
    private Integer paginaFirma;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @PrePersist
    void prePersist() {
        this.createdAt = LocalDateTime.now();
    }
}
