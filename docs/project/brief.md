# VIMz Private Proofs - Project Brief

## Overview
VIMz is a Flutter application implementing zero-knowledge proofs for authenticating image manipulations without revealing original content. Based on the 2024 PETS paper by Dziembowski et al., this app provides efficient proof generation and verification for high-resolution images using folding-based zkSNARKs.

## Problem Statement
- **Media authenticity crisis**: Ensuring credibility of daily internet media is increasingly difficult
- **Privacy vs authenticity trade-off**: Edited images need verification without exposing original sources
- **Performance barriers**: Traditional ZKPs have high computational costs and large proof sizes

## Solution
VIMz framework provides:
- **Efficient proving**: 13-25% faster than competition for 8K (33MP) images
- **Compact proofs**: < 11 KB proofs (90% smaller than alternatives)
- **Fast verification**: < 1 second verification time
- **Low memory**: Peak 10 GB memory usage
- **Privacy preservation**: Anonymous signers and editors
- **Chain integrity**: Provenance tracking through edit chains

## Key Features
1. **Image Upload & Processing**: Support for high-resolution images up to 8K
2. **Transformation Tracking**: Record and verify edit chains
3. **ZKP Generation**: Folding-based zkSNARK proof creation
4. **Proof Verification**: Instant verification of authenticity
5. **Privacy Protection**: Anonymous signing and editing
6. **Performance Benchmarks**: Real-time performance metrics
7. **C2PA Comparison**: Security analysis against industry standards

## Target Users
- **Content creators**: Journalists, photographers, designers
- **Media organizations**: News agencies, publishers
- **Verification services**: Fact-checkers, authenticity platforms
- **Privacy-conscious users**: Individuals needing secure image sharing

## Success Metrics
- Proof generation time < baseline by 13-25%
- Verification time < 1 second
- Proof size < 11 KB
- Memory usage < 10 GB peak
- Support for 8K resolution images
- Zero knowledge of original content
