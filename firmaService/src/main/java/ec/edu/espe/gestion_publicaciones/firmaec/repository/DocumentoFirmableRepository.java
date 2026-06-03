package ec.edu.espe.gestion_publicaciones.firmaec.repository;

import ec.edu.espe.gestion_publicaciones.firmaec.model.entity.DocumentoFirmableEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DocumentoFirmableRepository extends JpaRepository<DocumentoFirmableEntity, Long> {

    List<DocumentoFirmableEntity> findByEstado(String estado);

    List<DocumentoFirmableEntity> findByIdSolicitud(Long idSolicitud);
}
