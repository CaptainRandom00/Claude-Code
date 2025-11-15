# 🎯 Claude Agent Orchestration - Quick Reference

**Your 17 agents are fully operational! Use this guide for instant routing decisions.**

## ⚡ **Instant Agent Routing**

### 🏗️ **Architecture & Design** 
| When you need... | Auto-routes to... |
|------------------|-------------------|
| "Design the system architecture" | **chief-architect** |
| "Create API contracts" | **api-architect** |
| "Design database schema" | **database-architect** |
| "Plan cloud infrastructure" | **cloud-architect** |

### 💻 **Implementation**
| When you need... | Auto-routes to... |
|------------------|-------------------|
| "Build Python API endpoints" | **python-backend** |
| "Create React components" | **react-expert** |
| "Implement Node.js services" | **node-expert** |
| "Optimize frontend performance" | **frontend-perf** |

### ✅ **Quality & Operations**
| When you need... | Auto-routes to... |
|------------------|-------------------|
| "Write tests" or "Test this feature" | **qa-engineer** |
| "Security review" or "Audit security" | **security-auditor** |
| "Deploy" or "Set up CI/CD" | **devops-web** |
| "Coordinate complex task" | **tech-lead** |

### 🎨 **Business & UX**
| When you need... | Auto-routes to... |
|------------------|-------------------|
| "Research user needs" | **ux-researcher** |
| "Design the interface" | **ui-designer** |
| "SEO strategy" | **seo-strategist** |
| "Technical SEO optimization" | **technical-seo** |

### 🚨 **Problems & Decisions**
| When you need... | Auto-routes to... |
|------------------|-------------------|
| Any ambiguous request | **stuck → asks YOU** |
| Multiple valid approaches | **stuck → asks YOU** |
| Constitutional conflicts | **stuck → asks YOU** |

---

## 🔄 **Multi-Agent Workflow Examples**

### **"Build user authentication"**
```
chief-architect → System design
api-architect → Authentication API contracts  
database-architect → User/session schemas
security-auditor → Security model review
python-backend → API implementation
react-expert → Login/register UI
qa-engineer → Authentication testing
```

### **"Create admin dashboard"**
```
ux-researcher → Admin user needs
ui-designer → Dashboard wireframes
api-architect → Admin API contracts
python-backend → Admin endpoints  
react-expert → Dashboard components
frontend-perf → Performance optimization
qa-engineer → Admin workflow testing
```

### **"Build e-commerce checkout"**
```
chief-architect → Payment system architecture
api-architect → Payment API design
database-architect → Order/payment schemas
security-auditor → Payment security review
python-backend → Payment processing
react-expert → Checkout UI components
devops-web → Payment gateway deployment
qa-engineer → Checkout flow testing
```

---

## 🎯 **How to Use the System**

### ✅ **DO This**
- **Be specific**: "Create a React login form with validation"
- **Let Claude route**: Don't specify which agent to use
- **Trust the process**: When stuck agent asks questions, answer them
- **Think in phases**: Complex projects flow through multiple agents

### ❌ **Don't Do This**  
- Don't micromanage agent selection
- Don't bypass the stuck agent when it asks questions
- Don't expect instant solutions for complex problems
- Don't skip constitutional compliance suggestions

---

## 🚀 **Power User Commands**

### **Quick Development**
```
"Create a navbar component"                    → react-expert
"Build user registration API"                  → python-backend
"Set up PostgreSQL schema for blog"           → database-architect
"Write tests for the login flow"              → qa-engineer
```

### **Complex Coordination**
```
"Build a social media platform"               → Multi-agent workflow
"Create a fintech trading application"        → Architecture + security focus
"Develop a real-time analytics dashboard"     → Performance + data focus
```

### **Quality & Security**
```
"Audit the authentication system"             → security-auditor
"Optimize the entire application"             → frontend-perf + tech-lead
"Comprehensive testing strategy"              → qa-engineer + tech-lead
```

---

## 🔧 **Troubleshooting**

### **Problem**: Claude implements directly instead of delegating
**Solution**: Use orchestration prompts like "I need you to coordinate building..."

### **Problem**: stuck agent not responding to problems  
**Solution**: Agents are working correctly - provide clear answers to stuck agent questions

### **Problem**: Too many questions from stuck agent
**Solution**: Provide more context in your initial request to reduce ambiguity

### **Problem**: Agents not coordinating properly
**Solution**: Use tech-lead for complex multi-agent tasks: "Coordinate building..."

---

## 📱 **Constitutional Integration**

Your agents automatically enforce:
- ✅ **Test-First Development**: Tests before implementation
- ✅ **Security by Design**: Security built into everything  
- ✅ **Performance Standards**: Speed and optimization priorities
- ✅ **Simplicity**: Clear, maintainable solutions
- ✅ **Documentation**: Proper documentation standards

---

## 🎯 **Success Indicators**

You'll know the system is working when:
- ✅ Claude automatically delegates to the right specialist
- ✅ stuck agent asks you questions instead of guessing
- ✅ Agents coordinate seamlessly for complex tasks
- ✅ Constitutional principles are enforced automatically
- ✅ Quality gates prevent problems before they happen

---

**🚀 Your orchestrated agent workforce is ready! Start building amazing projects with coordinated specialist expertise.**
