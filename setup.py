from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="cyberpot",
    version="0.1.0",
    author="CyberPot Team",
    author_email="info@cyberpot.example.com",
    description="Advanced Network Security Platform",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/yourusername/cyberpot",
    packages=find_packages(include=['enterprise', 'enterprise.*']),
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
        "Development Status :: 3 - Alpha",
        "Intended Audience :: Information Technology",
        "Topic :: Security",
    ],
    python_requires=">=3.8",
    install_requires=[
        # Add your project's dependencies here
        "aiohttp>=3.8.0",
        "python-dateutil>=2.8.2",
        "pydantic>=1.10.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "pytest-cov>=3.0.0",
            "black>=22.0.0",
            "isort>=5.0.0",
            "mypy>=0.991",
            "flake8>=5.0.0",
        ],
    },
    entry_points={
        "console_scripts": [
            "cyberpot=enterprise.cli:main",
        ],
    },
)
