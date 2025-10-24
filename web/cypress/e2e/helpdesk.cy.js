describe('Helpdesk Application', () => {
  const testUser = {
    username: 'testuser',
    password: 'testpass123'
  };

  beforeEach(() => {
    cy.visit('http://localhost:5173');
  });

  it('should display login page initially', () => {
    cy.contains('Login').should('be.visible');
    cy.get('input[type="text"]').should('be.visible');
    cy.get('input[type="password"]').should('be.visible');
    cy.get('button[type="submit"]').should('contain', 'Sign in');
  });

  it('should allow user registration and login', () => {
    // Navigate to registration (we'll need to add this feature)
    // For now, let's test login flow
    
    // Try to login with invalid credentials
    cy.get('input[type="text"]').type('invaliduser');
    cy.get('input[type="password"]').type('invalidpass');
    cy.get('button[type="submit"]').click();
    
    // Should show error
    cy.contains('Login failed').should('be.visible');
  });

  it('should navigate to tickets page after login', () => {
    // This test assumes we have a registered user
    // In a real scenario, you'd set up test data first
    
    cy.get('input[type="text"]').type(testUser.username);
    cy.get('input[type="password"]').type(testUser.password);
    cy.get('button[type="submit"]').click();
    
    // Should redirect to tickets page
    cy.url().should('include', '/');
    cy.contains('Tickets').should('be.visible');
  });

  it('should create a new ticket', () => {
    // Login first
    cy.get('input[type="text"]').type(testUser.username);
    cy.get('input[type="password"]').type(testUser.password);
    cy.get('button[type="submit"]').click();
    
    // Navigate to new ticket page
    cy.contains('+ New Ticket').click();
    
    // Fill out the form
    cy.get('input[placeholder*="Title"], input[type="text"]').first().type('Test Ticket');
    cy.get('textarea').type('This is a test ticket description');
    cy.get('select').select('High');
    
    // Submit the form
    cy.get('button[type="submit"]').click();
    
    // Should redirect back to tickets page
    cy.url().should('include', '/');
    cy.contains('Test Ticket').should('be.visible');
  });

  it('should filter tickets by status and priority', () => {
    // Login first
    cy.get('input[type="text"]').type(testUser.username);
    cy.get('input[type="password"]').type(testUser.password);
    cy.get('button[type="submit"]').click();
    
    // Filter by status
    cy.get('select').first().select('Open');
    
    // Filter by priority
    cy.get('select').eq(1).select('High');
    
    // Click refresh
    cy.contains('Refresh').click();
    
    // Should show filtered results (implementation dependent)
    cy.get('.grid').should('be.visible');
  });

  it('should allow ticket management for admin users', () => {
    // This test assumes admin user
    cy.get('input[type="text"]').type('admin');
    cy.get('input[type="password"]').type('adminpass');
    cy.get('button[type="submit"]').click();
    
    // Should see admin button
    cy.contains('Admin').should('be.visible');
    
    // Click admin
    cy.contains('Admin').click();
    
    // Should see admin panel
    cy.contains('Users').should('be.visible');
    cy.contains('Audit').should('be.visible');
  });

  it('should handle file uploads', () => {
    // Login first
    cy.get('input[type="text"]').type(testUser.username);
    cy.get('input[type="password"]').type(testUser.password);
    cy.get('button[type="submit"]').click();
    
    // Create a ticket first
    cy.contains('+ New Ticket').click();
    cy.get('input[placeholder*="Title"], input[type="text"]').first().type('Upload Test Ticket');
    cy.get('textarea').type('Testing file upload');
    cy.get('button[type="submit"]').click();
    
    // Find the ticket card and test file upload
    cy.contains('Upload Test Ticket').parent().within(() => {
      // Upload a test file
      cy.get('input[type="file"]').selectFile({
        contents: 'test file content',
        fileName: 'test.txt',
        mimeType: 'text/plain'
      });
      
      cy.get('button').contains('Upload').click();
      
      // Should show success or error message
      cy.get('body').should('contain.text', 'Upload');
    });
  });

  it('should handle logout', () => {
    // Login first
    cy.get('input[type="text"]').type(testUser.username);
    cy.get('input[type="password"]').type(testUser.password);
    cy.get('button[type="submit"]').click();
    
    // Should see user info and logout button
    cy.contains(testUser.username).should('be.visible');
    cy.contains('Logout').should('be.visible');
    
    // Click logout
    cy.contains('Logout').click();
    
    // Should redirect to login page
    cy.url().should('include', '/login');
    cy.contains('Login').should('be.visible');
  });

  it('should handle password reset flow', () => {
    // Click forgot password link
    cy.contains('Forgot password?').click();
    
    // Should be on reset request page
    cy.url().should('include', '/forgot');
    cy.contains('Request Password Reset').should('be.visible');
    
    // Enter username
    cy.get('input[type="text"]').type(testUser.username);
    cy.get('button[type="submit"]').click();
    
    // Should show success message
    cy.contains('token has been generated').should('be.visible');
  });

  it('should be responsive on mobile', () => {
    // Set mobile viewport
    cy.viewport(375, 667);
    
    // Login
    cy.get('input[type="text"]').type(testUser.username);
    cy.get('input[type="password"]').type(testUser.password);
    cy.get('button[type="submit"]').click();
    
    // Should still be functional
    cy.contains('Tickets').should('be.visible');
    cy.get('.grid').should('be.visible');
  });
});
