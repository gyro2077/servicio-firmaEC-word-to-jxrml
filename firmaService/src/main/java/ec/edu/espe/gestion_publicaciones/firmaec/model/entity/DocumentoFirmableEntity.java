package ec.edu.espe.gestion_publicaciones.firmaec.model.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
@Entity
@Table(name = "documentos_firmables", schema = "publicaciones")
public class DocumentoFirmableEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_documento_firmable")
    private Long id;

    @Column(name = "id_solicitud")
    private Long idSolicitud;

    @Column(name = "id_tipo_documento", nullable = false)
    private Long idTipoDocumento;

    @Column(name = "pdf_base64", columnDefinition = "TEXT")
    private String pdfBase64;

    @Column(name = "nombre_archivo", length = 255)
    private String nombreArchivo;

    @Column(name = "total_firmas_requeridas", nullable = false)
    private int totalFirmasRequeridas;

    @Column(name = "firmas_completadas", nullable = false)
    private int firmasCompletadas = 0;

    @Column(name = "estado", nullable = false, length = 30)
    private String estado = "PENDIENTE";

    @OneToMany(mappedBy = "documentoFirmable", cascade = CascadeType.ALL,
               orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("ordenFirma ASC")
    private List<FirmaElectronicaEntity> firmas = new ArrayList<>();

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    void prePersist() {
        var now = LocalDateTime.now();
        this.createdAt = now;
        this.updatedAt = now;
    }

    @PreUpdate
    void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
