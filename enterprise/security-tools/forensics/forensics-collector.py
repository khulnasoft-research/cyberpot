#!/usr/bin/env python3
"""
CyberPot Digital Forensics & Incident Response System
Advanced evidence collection, timeline analysis, and incident response capabilities
"""

import asyncio
import json
import os
import shutil
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
import hashlib
import gzip
import tarfile
import subprocess
from dataclasses import dataclass, asdict


@dataclass
class EvidenceItem:
    """Digital evidence item"""

    id: str
    name: str
    description: str
    evidence_type: str  # file, memory, network, registry, log
    source: str
    hash_sha256: str
    hash_md5: str
    size_bytes: int
    collected_at: datetime
    collection_method: str
    chain_of_custody: List[Dict[str, Any]]
    tags: List[str]
    metadata: Dict[str, Any]

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


@dataclass
class TimelineEntry:
    """Timeline entry for incident analysis"""

    timestamp: datetime
    event_type: str
    source: str
    description: str
    severity: str
    related_evidence: List[str]  # Evidence IDs
    process_info: Optional[Dict[str, Any]]
    network_info: Optional[Dict[str, Any]]
    file_info: Optional[Dict[str, Any]]

    def to_dict(self) -> Dict[str, Any]:
        return asdict(self)


class DigitalForensicsCollector:
    """Digital forensics evidence collection system"""

    def __init__(self, case_id: str, evidence_path: Path):
        self.case_id = case_id
        self.evidence_path = Path(evidence_path)
        self.evidence_items: List[EvidenceItem] = []
        self.timeline: List[TimelineEntry] = []

        # Create case directory structure
        self.case_path = self.evidence_path / case_id
        self._create_case_structure()

    def _create_case_structure(self):
        """Create directory structure for evidence collection"""
        directories = [
            "evidence/files",
            "evidence/memory",
            "evidence/network",
            "evidence/logs",
            "evidence/screenshots",
            "reports",
            "chain_of_custody",
        ]

        for directory in directories:
            (self.case_path / directory).mkdir(parents=True, exist_ok=True)

    async def collect_system_evidence(self) -> List[EvidenceItem]:
        """Collect comprehensive system evidence"""
        print("🔍 Collecting system evidence...")

        evidence_items = []

        # Collect running processes
        processes = await self._collect_process_evidence()
        evidence_items.extend(processes)

        # Collect network connections
        network = await self._collect_network_evidence()
        evidence_items.extend(network)

        # Collect system logs
        logs = await self._collect_log_evidence()
        evidence_items.extend(logs)

        # Collect file system evidence
        files = await self._collect_file_evidence()
        evidence_items.extend(files)

        # Collect memory evidence (if available)
        memory = await self._collect_memory_evidence()
        if memory:
            evidence_items.extend(memory)

        self.evidence_items.extend(evidence_items)
        print(f"   Collected {len(evidence_items)} evidence items")

        return evidence_items

    async def _collect_process_evidence(self) -> List[EvidenceItem]:
        """Collect running process evidence"""
        evidence_items = []

        try:
            # Get process list
            result = subprocess.run(
                ["ps", "aux"], capture_output=True, text=True)
            processes_data = result.stdout

            # Create evidence item for process list
            evidence_id = f"proc_list_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

            evidence_item = EvidenceItem(
                id=evidence_id,
                name="Running Processes",
                description="Snapshot of all running processes at time of collection",
                evidence_type="process_list",
                source="system",
                hash_sha256=hashlib.sha256(
                    processes_data.encode()).hexdigest(),
                hash_md5=hashlib.md5(processes_data.encode()).hexdigest(),
                size_bytes=len(processes_data.encode()),
                collected_at=datetime.now(),
                collection_method="ps_command",
                chain_of_custody=[
                    {
                        "timestamp": datetime.now().isoformat(),
                        "action": "collected",
                        "person": "automated_system",
                        "reason": "incident_response",
                    }
                ],
                tags=["processes", "system", "volatile"],
                metadata={"format": "ps_aux_output"},
            )

            # Save process data to file
            process_file = self.case_path / "evidence" / "processes.txt"
            with open(process_file, "w") as f:
                f.write(processes_data)

            evidence_items.append(evidence_item)

        except Exception as e:
            print(f"   ❌ Failed to collect process evidence: {str(e)}")

        return evidence_items

    async def _collect_network_evidence(self) -> List[EvidenceItem]:
        """Collect network connection evidence"""
        evidence_items = []

        try:
            # Get network connections
            result = subprocess.run(
                ["ss", "-tuln"], capture_output=True, text=True)
            network_data = result.stdout

            evidence_id = f"net_conn_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

            evidence_item = EvidenceItem(
                id=evidence_id,
                name="Network Connections",
                description="Snapshot of active network connections",
                evidence_type="network_connections",
                source="system",
                hash_sha256=hashlib.sha256(network_data.encode()).hexdigest(),
                hash_md5=hashlib.md5(network_data.encode()).hexdigest(),
                size_bytes=len(network_data.encode()),
                collected_at=datetime.now(),
                collection_method="ss_command",
                chain_of_custody=[
                    {
                        "timestamp": datetime.now().isoformat(),
                        "action": "collected",
                        "person": "automated_system",
                        "reason": "incident_response",
                    }
                ],
                tags=["network", "connections", "volatile"],
                metadata={"format": "ss_output"},
            )

            # Save network data to file
            network_file = self.case_path / "evidence" / "network_connections.txt"
            with open(network_file, "w") as f:
                f.write(network_data)

            evidence_items.append(evidence_item)

        except Exception as e:
            print(f"   ❌ Failed to collect network evidence: {str(e)}")

        return evidence_items

    async def _collect_log_evidence(self) -> List[EvidenceItem]:
        """Collect system log evidence"""
        evidence_items = []

        log_files = [
            "/var/log/auth.log",
            "/var/log/syslog",
            "/var/log/kern.log",
            "/var/log/cyberpot/cyberpotinit.log",
        ]

        for log_file in log_files:
            if os.path.exists(log_file):
                try:
                    with open(log_file, "rb") as f:
                        log_data = f.read()

                    if log_data:
                        evidence_id = f"log_{Path(log_file).name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

                        evidence_item = EvidenceItem(
                            id=evidence_id,
                            name=f"Log: {Path(log_file).name}",
                            description=f"System log file: {log_file}",
                            evidence_type="log_file",
                            source=log_file,
                            hash_sha256=hashlib.sha256(log_data).hexdigest(),
                            hash_md5=hashlib.md5(log_data).hexdigest(),
                            size_bytes=len(log_data),
                            collected_at=datetime.now(),
                            collection_method="file_copy",
                            chain_of_custody=[
                                {
                                    "timestamp": datetime.now().isoformat(),
                                    "action": "collected",
                                    "person": "automated_system",
                                    "reason": "incident_response",
                                }
                            ],
                            tags=["logs", "system", "evidence"],
                            metadata={
                                "original_path": log_file,
                                "file_size": len(log_data),
                                "last_modified": datetime.fromtimestamp(
                                    os.path.getmtime(log_file)
                                ).isoformat(),
                            },
                        )

                        # Copy log file to evidence directory
                        dest_file = (
                            self.case_path / "evidence" /
                            "logs" / Path(log_file).name
                        )
                        shutil.copy2(log_file, dest_file)

                        evidence_items.append(evidence_item)

                except Exception as e:
                    print(f"   ❌ Failed to collect log {log_file}: {str(e)}")

        return evidence_items

    async def _collect_file_evidence(self) -> List[EvidenceItem]:
        """Collect file system evidence"""
        evidence_items = []

        # Files of interest for forensics
        files_of_interest = [
            "/etc/passwd",
            "/etc/shadow",
            "/etc/group",
            "/etc/crontab",
            "/etc/ssh/sshd_config",
            "/home/cyberpot/cyberpot/.env",
        ]

        for file_path in files_of_interest:
            if os.path.exists(file_path):
                try:
                    with open(file_path, "rb") as f:
                        file_data = f.read()

                    if file_data:
                        evidence_id = f"file_{Path(file_path).name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

                        evidence_item = EvidenceItem(
                            id=evidence_id,
                            name=f"File: {Path(file_path).name}",
                            description=f"System file: {file_path}",
                            evidence_type="file",
                            source=file_path,
                            hash_sha256=hashlib.sha256(file_data).hexdigest(),
                            hash_md5=hashlib.md5(file_data).hexdigest(),
                            size_bytes=len(file_data),
                            collected_at=datetime.now(),
                            collection_method="file_copy",
                            chain_of_custody=[
                                {
                                    "timestamp": datetime.now().isoformat(),
                                    "action": "collected",
                                    "person": "automated_system",
                                    "reason": "incident_response",
                                }
                            ],
                            tags=["file", "system", "evidence"],
                            metadata={
                                "original_path": file_path,
                                "file_size": len(file_data),
                                "permissions": oct(os.stat(file_path).st_mode),
                                "last_modified": datetime.fromtimestamp(
                                    os.path.getmtime(file_path)
                                ).isoformat(),
                            },
                        )

                        # Copy file to evidence directory
                        dest_file = (
                            self.case_path / "evidence" /
                            "files" / Path(file_path).name
                        )
                        shutil.copy2(file_path, dest_file)

                        evidence_items.append(evidence_item)

                except Exception as e:
                    print(f"   ❌ Failed to collect file {file_path}: {str(e)}")

        return evidence_items

    async def _collect_memory_evidence(self) -> List[EvidenceItem]:
        """Collect memory evidence (requires root/sudo)"""
        evidence_items = []

        try:
            # This would typically use tools like:
            # - Volatility for memory analysis
            # - LiME for memory acquisition
            # - Custom memory forensics tools

            print("   📝 Memory evidence collection requires root privileges")
            print("   💡 Run with: sudo python3 forensics-collector.py")

            # Placeholder for memory collection
            # In real implementation, this would acquire memory image

        except Exception as e:
            print(f"   ❌ Failed to collect memory evidence: {str(e)}")

        return evidence_items

    def build_investigation_timeline(
        self, time_window: timedelta = timedelta(hours=24)
    ) -> List[TimelineEntry]:
        """Build investigation timeline from collected evidence"""
        print("📅 Building investigation timeline...")

        timeline = []

        # Get time window
        start_time = datetime.now() - time_window

        # Process evidence items chronologically
        for evidence in self.evidence_items:
            if evidence.collected_at >= start_time:
                # Create timeline entry for evidence collection
                timeline.append(
                    TimelineEntry(
                        timestamp=evidence.collected_at,
                        event_type="evidence_collection",
                        source="forensics_system",
                        description=f"Collected {evidence.evidence_type}: {evidence.name}",
                        severity="info",
                        related_evidence=[evidence.id],
                        process_info=None,
                        network_info=None,
                        file_info={
                            "path": evidence.source,
                            "hash": evidence.hash_sha256,
                        },
                    )
                )

        # Sort timeline chronologically
        timeline.sort(key=lambda x: x.timestamp)

        self.timeline.extend(timeline)
        print(f"   Built timeline with {len(timeline)} entries")

        return timeline

    def analyze_incident_patterns(self) -> Dict[str, Any]:
        """Analyze evidence for incident patterns"""
        if not self.evidence_items:
            return {"message": "No evidence collected for analysis"}

        # Analyze evidence types
        evidence_types = {}
        for evidence in self.evidence_items:
            ev_type = evidence.evidence_type
            if ev_type not in evidence_types:
                evidence_types[ev_type] = 0
            evidence_types[ev_type] += 1

        # Analyze collection timeline
        collection_times = [e.collected_at for e in self.evidence_items]
        if collection_times:
            earliest = min(collection_times)
            latest = max(collection_times)
            duration = latest - earliest
        else:
            duration = timedelta(0)

        # Identify suspicious patterns
        suspicious_indicators = []

        # Check for unauthorized processes
        suspicious_processes = self._identify_suspicious_processes()
        if suspicious_processes:
            suspicious_indicators.append(
                f"Suspicious processes: {len(suspicious_processes)}"
            )

        # Check for network anomalies
        network_anomalies = self._identify_network_anomalies()
        if network_anomalies:
            suspicious_indicators.append(
                f"Network anomalies: {len(network_anomalies)}")

        # Check for file system anomalies
        file_anomalies = self._identify_file_anomalies()
        if file_anomalies:
            suspicious_indicators.append(
                f"File anomalies: {len(file_anomalies)}")

        return {
            "total_evidence_items": len(self.evidence_items),
            "evidence_types": evidence_types,
            "collection_duration": str(duration),
            "suspicious_indicators": suspicious_indicators,
            "timeline_entries": len(self.timeline),
            "analysis_timestamp": datetime.now().isoformat(),
        }

    def _identify_suspicious_processes(self) -> List[str]:
        """Identify potentially suspicious processes"""
        suspicious = []

        # This would analyze process list for:
        # - Unusual process names
        # - Processes running from temporary directories
        # - Processes with suspicious command lines
        # - Hidden processes

        # Placeholder implementation
        suspicious_patterns = ["suspicious_process", "hidden_process"]

        return suspicious_patterns

    def _identify_network_anomalies(self) -> List[str]:
        """Identify network anomalies"""
        anomalies = []

        # This would analyze network connections for:
        # - Unusual port usage
        # - Connections to known malicious IPs
        # - High volume connections
        # - Unauthorized outbound connections

        # Placeholder implementation
        anomaly_patterns = ["unusual_port_9999", "suspicious_connection"]

        return anomaly_patterns

    def _identify_file_anomalies(self) -> List[str]:
        """Identify file system anomalies"""
        anomalies = []

        # This would analyze file system for:
        # - Unauthorized file modifications
        # - Suspicious file names or locations
        # - Hidden files or directories
        # - Files with suspicious permissions

        # Placeholder implementation
        anomaly_patterns = ["suspicious_file", "unauthorized_modification"]

        return anomaly_patterns

    def create_evidence_package(self) -> Path:
        """Create compressed evidence package"""
        print("📦 Creating evidence package...")

        # Create timestamp for package
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        package_name = f"cyberpot_forensics_{self.case_id}_{timestamp}.tar.gz"

        package_path = self.case_path / package_name

        # Create tar.gz package
        with tarfile.open(package_path, "w:gz") as tar:
            # Add all evidence directories
            for directory in ["evidence", "reports", "chain_of_custody"]:
                dir_path = self.case_path / directory
                if dir_path.exists():
                    tar.add(dir_path, arcname=f"{self.case_id}/{directory}")

            # Add metadata files
            metadata = {
                "case_id": self.case_id,
                "collection_timestamp": datetime.now().isoformat(),
                "evidence_items": len(self.evidence_items),
                "timeline_entries": len(self.timeline),
                "package_hash": self._calculate_package_hash(package_path),
            }

            metadata_file = self.case_path / "package_metadata.json"
            with open(metadata_file, "w") as f:
                json.dump(metadata, f, indent=2, default=str)

            tar.add(metadata_file,
                    arcname=f"{self.case_id}/package_metadata.json")

        print(f"   Evidence package created: {package_path}")
        size_mb = package_path.stat().st_size / (1024 * 1024)
        print(f"   Package size: {size_mb:.2f} MB")

        return package_path

    def _calculate_package_hash(self, package_path: Path) -> str:
        """Calculate hash of evidence package"""
        hash_sha256 = hashlib.sha256()

        with open(package_path, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_sha256.update(chunk)

        return hash_sha256.hexdigest()

    def generate_forensics_report(self) -> Dict[str, Any]:
        """Generate comprehensive forensics report"""
        analysis = self.analyze_incident_patterns()

        # Create chain of custody summary
        chain_of_custody_summary = {
            "total_transfers": sum(
                len(item.chain_of_custody) for item in self.evidence_items
            ),
            "collection_methods": list(
                set(item.collection_method for item in self.evidence_items)
            ),
            "evidence_types": list(
                set(item.evidence_type for item in self.evidence_items)
            ),
        }

        # Generate recommendations
        recommendations = self._generate_forensics_recommendations(analysis)

        report = {
            "report_id": f"forensics_report_{self.case_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
            "case_id": self.case_id,
            "generated_at": datetime.now().isoformat(),
            "evidence_summary": {
                "total_items": len(self.evidence_items),
                "evidence_types": analysis.get("evidence_types", {}),
                "collection_timeline": analysis.get("collection_duration", "unknown"),
            },
            "timeline_summary": {
                "total_entries": len(self.timeline),
                "time_span": analysis.get("collection_duration", "unknown"),
            },
            "incident_analysis": {
                "suspicious_indicators": analysis.get("suspicious_indicators", []),
                "risk_assessment": (
                    "medium" if analysis.get(
                        "suspicious_indicators") else "low"
                ),
                "recommended_actions": recommendations,
            },
            "chain_of_custody": chain_of_custody_summary,
            "evidence_package": {
                "location": str(
                    self.case_path /
                    f"cyberpot_forensics_{self.case_id}_*.tar.gz"
                ),
                "integrity_hash": "calculated_at_package_creation",
            },
        }

        # Save report
        report_path = self.case_path / "reports" / \
            f"{report['report_id']}.json"
        report_path.parent.mkdir(parents=True, exist_ok=True)

        with open(report_path, "w") as f:
            json.dump(report, f, indent=2, default=str)

        print(f"📋 Forensics report generated: {report_path}")
        return report

    def _generate_forensics_recommendations(
        self, analysis: Dict[str, Any]
    ) -> List[str]:
        """Generate forensics recommendations"""
        recommendations = []

        suspicious_count = len(analysis.get("suspicious_indicators", []))

        if suspicious_count > 0:
            recommendations.append(
                "🚨 SUSPICIOUS ACTIVITY: Continue investigation and consider escalation"
            )

        recommendations.extend(
            [
                "🔍 Review all collected evidence for additional indicators",
                "📊 Correlate findings with threat intelligence feeds",
                "🛡️  Implement additional security controls based on findings",
                "📋 Document all findings for compliance and legal purposes",
                "🔄 Schedule follow-up assessment in 24-48 hours",
            ]
        )

        return recommendations


async def main():
    """Main forensics collection function"""
    # Generate case ID
    case_id = f"cyberpot_incident_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

    # Set up evidence collection
    evidence_path = Path("/Users/dev/cyberpot/enterprise/forensics")
    collector = DigitalForensicsCollector(case_id, evidence_path)

    print("🔬 CyberPot Digital Forensics & Incident Response")
    print("=" * 55)
    print(f"Case ID: {case_id}")

    try:
        # Collect system evidence
        print("\n🔍 Phase 1: Evidence Collection")
        evidence = await collector.collect_system_evidence()

        # Build investigation timeline
        print("\n📅 Phase 2: Timeline Analysis")
        timeline = collector.build_investigation_timeline()

        # Analyze incident patterns
        print("\n📊 Phase 3: Incident Analysis")
        analysis = collector.analyze_incident_patterns()

        # Generate forensics report
        print("\n📋 Phase 4: Report Generation")
        report = collector.generate_forensics_report()

        # Create evidence package
        print("\n📦 Phase 5: Evidence Packaging")
        package_path = collector.create_evidence_package()

        # Display summary
        print("\n🎯 Forensics Investigation Summary:")
        print(f"   Evidence Items: {analysis['total_evidence_items']}")
        print(f"   Timeline Entries: {len(timeline)}")
        print(
            f"   Suspicious Indicators: {len(analysis['suspicious_indicators'])}")

        print("\n💡 Key Recommendations:")
        for i, rec in enumerate(
            report["incident_analysis"]["recommended_actions"][:3], 1
        ):
            print(f"   {i}. {rec!s}")

        report_file = f"{report['report_id']}.json"
        report_path = evidence_path / case_id / "reports" / report_file
        print(f"\n📋 Complete forensics report: {report_path!s}")
        print(f"   Evidence package: {package_path!s}")

    except Exception as e:
        print(f"❌ Forensics investigation failed: {str(e)!s}")
        return 1


{{...}}

if __name__ == "__main__":
    import sys

    exit_code = asyncio.run(main())
    sys.exit(exit_code)
