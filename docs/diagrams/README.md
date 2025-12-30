# SafeEats Architecture Diagrams

This directory contains architectural diagrams for the SafeEats application.

## Viewing Diagrams

The diagrams are created using Mermaid markdown syntax. You can view them:
1. Directly on GitHub (renders Mermaid automatically)
2. Using VS Code with the Mermaid extension
3. At [mermaid.live](https://mermaid.live) by pasting the code

## Diagrams

### ⭐ Master Flow Diagram Document
| Diagram | Description |
|---------|-------------|
| [project-flow-diagrams.md](project-flow-diagrams.md) | **Comprehensive collection** of all application flows, architecture, state machines, and data flows (10 diagrams) |

### Sequence Diagrams
| Diagram | Description |
|---------|-------------|
| [sequence-scan-flow.md](sequence-scan-flow.md) | Complete barcode scanning flow from user action to result display |

### Block Diagrams
| Diagram | Description |
|---------|-------------|
| [block-system-architecture.md](block-system-architecture.md) | High-level system architecture showing all layers |

### Flow Diagrams
| Diagram | Description |
|---------|-------------|
| [flow-risk-classification.md](flow-risk-classification.md) | Risk classification decision tree and conflict resolution |

### Class Diagrams
| Diagram | Description |
|---------|-------------|
| [class-domain-entities.md](class-domain-entities.md) | Domain entities (Product, Ingredient, Carcinogen, etc.) |
| [class-data-layer.md](class-data-layer.md) | Data layer (Repositories, DataSources, Models) |

### State Diagrams
| Diagram | Description |
|---------|-------------|
| [state-product-bloc.md](state-product-bloc.md) | ProductBloc state machine and event handling |

### Backend Architecture
| Diagram | Description |
|---------|-------------|
| [backend-architecture.md](backend-architecture.md) | FastAPI backend structure, caching, error handling |

## Quick Reference

### Overall Architecture
```
┌──────────────────────────────────────────────────────────────┐
│                    Flutter App (Client)                       │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐             │
│  │   Pages    │→ │   BLoCs    │→ │ Use Cases  │             │
│  └────────────┘  └────────────┘  └────────────┘             │
│                         ↓                                     │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                   Repositories                          │ │
│  │   ProductRepo  │  CarcinogenRepo  │  HistoryRepo       │ │
│  └────────────────────────────────────────────────────────┘ │
│                         ↓                                     │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                   Data Sources                          │ │
│  │  Backend DS (primary)  │  OFF DS (fallback)  │  Local  │ │
│  └────────────────────────────────────────────────────────┘ │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                  SafeEats Backend (FastAPI)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐       │
│  │  /scan       │→ │ Risk Rules   │→ │ SQLite Cache │       │
│  │  endpoint    │  │ (v1.0.0)     │  │              │       │
│  └──────────────┘  └──────────────┘  └──────────────┘       │
└────────────────────────────┬─────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                   Open Food Facts API                         │
└──────────────────────────────────────────────────────────────┘
```

### Risk Level Color Mapping
| Level | Value | Color | IARC |
|-------|-------|-------|------|
| Safe | 0 | 🟢 | - |
| Low | 1 | 🟢 | Group 3 |
| Moderate | 2 | 🟡 | Group 2B |
| High | 3 | 🟠 | Group 2A |
| Critical | 4 | 🔴 | Group 1 |