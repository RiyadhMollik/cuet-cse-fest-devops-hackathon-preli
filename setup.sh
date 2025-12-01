#!/bin/bash

# CUET CSE Fest DevOps Hackathon - Quick Setup Script
# This script automates the setup and verification of the entire system

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  CUET CSE Fest DevOps Hackathon - Quick Setup Script            ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

print_step() {
    echo -e "${BLUE}[Step $1/$2] $3${NC}"
}

check_prerequisites() {
    print_step 1 6 "Checking prerequisites..."
    
    # Check Docker
    if command -v docker &> /dev/null; then
        print_success "Docker is installed ($(docker --version))"
    else
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if docker compose version &> /dev/null; then
        print_success "Docker Compose is installed ($(docker compose version))"
    else
        print_error "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    # Check Docker daemon
    if docker ps &> /dev/null; then
        print_success "Docker daemon is running"
    else
        print_error "Docker daemon is not running. Please start Docker."
        exit 1
    fi
    
    # Check Make
    if command -v make &> /dev/null; then
        print_success "Make is installed"
    else
        print_error "Make is not installed. Please install Make first."
        exit 1
    fi
    
    # Check curl
    if command -v curl &> /dev/null; then
        print_success "curl is installed"
    else
        print_error "curl is not installed. Please install curl first."
        exit 1
    fi
    
    echo ""
}

check_env_file() {
    print_step 2 6 "Checking environment configuration..."
    
    if [ -f .env ]; then
        print_success ".env file exists"
        
        # Check required variables
        required_vars=("MONGO_INITDB_ROOT_USERNAME" "MONGO_INITDB_ROOT_PASSWORD" "MONGO_URI" "MONGO_DATABASE" "BACKEND_PORT" "GATEWAY_PORT" "NODE_ENV")
        
        for var in "${required_vars[@]}"; do
            if grep -q "^${var}=" .env; then
                value=$(grep "^${var}=" .env | cut -d '=' -f2)
                if [ -n "$value" ]; then
                    print_success "$var is set"
                else
                    print_error "$var is empty in .env file"
                    exit 1
                fi
            else
                print_error "$var is missing from .env file"
                exit 1
            fi
        done
    else
        print_error ".env file not found"
        exit 1
    fi
    
    echo ""
}

cleanup_existing() {
    print_step 3 6 "Cleaning up existing containers..."
    
    print_info "Stopping any running containers..."
    make clean &> /dev/null || true
    
    print_success "Cleanup completed"
    echo ""
}

build_images() {
    print_step 4 6 "Building Docker images..."
    
    MODE=${1:-dev}
    
    print_info "Building $MODE images (this may take a few minutes)..."
    
    if [ "$MODE" = "prod" ]; then
        make prod-build
    else
        make dev-build
    fi
    
    print_success "Images built successfully"
    echo ""
}

start_services() {
    print_step 5 6 "Starting services..."
    
    MODE=${1:-dev}
    
    print_info "Starting $MODE environment..."
    
    if [ "$MODE" = "prod" ]; then
        make prod-up
    else
        make dev-up
    fi
    
    print_success "Services started"
    echo ""
}

verify_deployment() {
    print_step 6 6 "Verifying deployment..."
    
    print_info "Waiting for services to be ready (30 seconds)..."
    sleep 30
    
    # Check gateway health
    print_info "Checking gateway health..."
    if curl -s http://localhost:5921/health | grep -q '"ok":true'; then
        print_success "Gateway is healthy"
    else
        print_error "Gateway health check failed"
        exit 1
    fi
    
    # Check backend health via gateway
    print_info "Checking backend health via gateway..."
    if curl -s http://localhost:5921/api/health | grep -q '"ok":true'; then
        print_success "Backend is healthy (via gateway)"
    else
        print_error "Backend health check failed"
        exit 1
    fi
    
    # Test product creation
    print_info "Testing product creation..."
    response=$(curl -s -X POST http://localhost:5921/api/products \
        -H 'Content-Type: application/json' \
        -d '{"name":"Test Product","price":99.99}')
    
    if echo "$response" | grep -q '"name":"Test Product"'; then
        print_success "Product creation successful"
    else
        print_error "Product creation failed"
        print_error "Response: $response"
        exit 1
    fi
    
    # Test product listing
    print_info "Testing product listing..."
    if curl -s http://localhost:5921/api/products | grep -q '"name":"Test Product"'; then
        print_success "Product listing successful"
    else
        print_error "Product listing failed"
        exit 1
    fi
    
    # Security test - verify backend is not directly accessible
    print_info "Testing security (backend should NOT be directly accessible)..."
    if ! curl -s --max-time 5 http://localhost:3847/api/products &> /dev/null; then
        print_success "Backend is properly secured (not directly accessible)"
    else
        print_error "Security issue: Backend is directly accessible!"
        exit 1
    fi
    
    echo ""
    print_success "All verification tests passed! ✓"
    echo ""
}

show_summary() {
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    Setup Completed Successfully!                 ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Service URLs:${NC}"
    echo "  Gateway:  http://localhost:5921"
    echo "  Health:   http://localhost:5921/health"
    echo "  API:      http://localhost:5921/api/products"
    echo ""
    echo -e "${YELLOW}Useful Commands:${NC}"
    echo "  View logs:        make dev-logs"
    echo "  Check status:     make dev-ps"
    echo "  Stop services:    make dev-down"
    echo "  Access shell:     make backend-shell"
    echo "  View all commands: make help"
    echo ""
    echo -e "${YELLOW}Quick Tests:${NC}"
    echo "  curl http://localhost:5921/health"
    echo "  curl http://localhost:5921/api/products"
    echo "  curl -X POST http://localhost:5921/api/products -H 'Content-Type: application/json' -d '{\"name\":\"Product\",\"price\":99.99}'"
    echo ""
    echo -e "${GREEN}Happy coding! 🚀${NC}"
    echo ""
}

show_usage() {
    echo "Usage: $0 [MODE]"
    echo ""
    echo "MODE:"
    echo "  dev   - Start in development mode (default)"
    echo "  prod  - Start in production mode"
    echo ""
    echo "Examples:"
    echo "  $0           # Start in development mode"
    echo "  $0 dev       # Start in development mode"
    echo "  $0 prod      # Start in production mode"
    echo ""
}

# Main execution
main() {
    # Parse arguments
    MODE=${1:-dev}
    
    if [ "$MODE" != "dev" ] && [ "$MODE" != "prod" ]; then
        print_error "Invalid mode: $MODE"
        show_usage
        exit 1
    fi
    
    print_header
    
    check_prerequisites
    check_env_file
    cleanup_existing
    build_images "$MODE"
    start_services "$MODE"
    verify_deployment
    show_summary
}

# Run main function
main "$@"
