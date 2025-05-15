# DICOM Load Balancer (WIP)

A scalable, high-performance DICOM load-balancer and router designed for medical imaging workflows. This solution provides zero-downtime operation for PACS (Picture Archiving and Communication System) environments, supporting advanced routing rules, automated health-checks, and seamless integration into any medical-imaging infrastructure.

## Features

- **High-Performance Load Balancing**: Efficiently distribute DICOM traffic across multiple PACS nodes
- **Zero-Downtime Operation**: Ensure continuous service availability for critical medical imaging workflows
- **Advanced Routing Rules**: Route DICOM studies based on modality, body part, institution, and other DICOM tags
- **Automated Health Checks**: Continuously monitor destination nodes and automatically redirect traffic from failed nodes
- **Horizontal Scaling**: Deploy multiple instances for increased throughput and reliability
- **Comprehensive Metrics**: Monitor performance, throughput, and system health with detailed metrics
- **DICOM Compliance**: Full compatibility with DICOM standards for seamless integration

## Architecture

This project combines HAProxy for TCP load balancing with DCMTK tools for DICOM processing. The architecture includes:

1. **Frontend Service (HAProxy)**: Listens on port 11112 for incoming DICOM connections
2. **Routing Logic (Lua)**: Parses DICOM headers and routes traffic based on modality and other DICOM tags
3. **Backend Services**: Multiple DICOM storage nodes available for routing traffic
4. **Health Monitoring**: Automated health checks to ensure backends are available

## Requirements

- Docker/Podman for container deployment
- Basic understanding of DICOM and PACS architecture

## Installation

### Using Docker/Podman

1. Clone this repository:
   ```
   git clone https://github.com/your-username/dicom-loadbalancer.git
   cd dicom-loadbalancer
   ```

2. Build the container:
   ```
   make build
   ```

3. Run the container:
   ```
   make run
   ```

## Configuration

### HAProxy Configuration

The main configuration file is located at `config/haproxy.cfg`. This file defines:
- Frontend and backend services
- TCP listening ports
- Health check parameters
- DICOM routing rules

### DICOM Routing

DICOM routing is implemented in `scripts/parser.lua`. This Lua script:
- Extracts relevant DICOM tags from incoming requests
- Applies routing rules based on modality, SOP Class UID, patient ID, etc.
- Routes traffic to appropriate backends based on these rules

Example routing rules:
- CT images → CT servers
- MR images → MR servers
- Patient-based load balancing → General servers 1-3

## Testing

The project includes a directory for DICOM samples that can be used for testing:

```
make run
```

This will start the container with the sample DICOM directory mounted.

## Dashboard & Monitoring

The HAProxy stats dashboard is available at:
```
http://localhost:8404/stats
```

Default credentials: `admin:yourpassword` (configurable in haproxy.cfg)

## Development

### Project Structure

- `config/` - Configuration files for HAProxy
- `scripts/` - Lua scripts for DICOM routing and forwarding
- `dicom-samples/` - Test DICOM files
- `Dockerfile` - Container definition using Alpine Linux and DCMTK
- `Makefile` - Build and run commands
- `entrypoint.sh` - Container startup script

### Version Management

The project uses semantic versioning. To bump the version:

```
make bump-version
```

## License

See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

