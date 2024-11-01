// Include standard headers
#include <iostream>
#include <cmath>
#include <chrono> // For time-based rotation

// Include glad
#include <glad/glad.h>

// Include GLFW
#include <GLFW/glfw3.h>

// Shader sources
const char* vertexShaderSource = R"glsl(
#version 330 core
layout(location = 0) in vec3 aPos;
uniform mat4 uMVP;
void main()
{
    gl_Position = uMVP * vec4(aPos, 1.0);
}
)glsl";

const char* fragmentShaderSource = R"glsl(
#version 330 core
uniform vec3 uColor;
out vec4 FragColor;
void main()
{
    FragColor = vec4(uColor, 1.0);
}
)glsl";

// Global variables
GLFWwindow* window;
int width = 800, height = 600;

// Camera parameters
float angleX = 0.0f, angleY = 0.0f, distance = 5.0f;

// Timing variables for automatic rotation
float deltaTime = 0.0f; // Time between current frame and last frame
float lastFrame = 0.0f;

// Define a 3D vector class
class Vector3 {
public:
    float x, y, z;

    Vector3() : x(0), y(0), z(0) {}
    Vector3(float xi, float yi, float zi) : x(xi), y(yi), z(zi) {}

    // Vector addition
    Vector3 operator+(const Vector3& v) const {
        return Vector3(x + v.x, y + v.y, z + v.z);
    }

    // Vector subtraction
    Vector3 operator-(const Vector3& v) const {
        return Vector3(x - v.x, y - v.y, z - v.z);
    }

    // Scalar multiplication
    Vector3 operator*(float s) const {
        return Vector3(x * s, y * s, z * s);
    }

    // Scalar division
    Vector3 operator/(float s) const {
        return Vector3(x / s, y / s, z / s);
    }

    // Unary minus operator
    Vector3 operator-() const {
        return Vector3(-x, -y, -z);
    }

    // Vector length
    float length() const {
        return sqrtf(x * x + y * y + z * z);
    }

    // Normalize vector
    Vector3 normalized() const {
        float len = length();
        if (len > 0)
            return (*this) / len;
        else
            return Vector3(0, 0, 0);
    }

    // Cross product
    Vector3 cross(const Vector3& v) const {
        return Vector3(y * v.z - z * v.y,
            z * v.x - x * v.z,
            x * v.y - y * v.x);
    }

    // Dot product
    float dot(const Vector3& v) const {
        return x * v.x + y * v.y + z * v.z;
    }
};

// Define a 4x4 matrix class
class Matrix4 {
public:
    float m[16]; // Column-major order

    Matrix4() {
        loadIdentity();
    }

    // Load identity matrix
    void loadIdentity() {
        for (int i = 0; i < 16; ++i)
            m[i] = 0;
        m[0] = m[5] = m[10] = m[15] = 1.0f;
    }

    // Matrix multiplication
    Matrix4 operator*(const Matrix4& mat) const {
        Matrix4 result;
        for (int row = 0; row < 4; ++row) {
            for (int col = 0; col < 4; ++col) {
                // Perform the dot product of the row from the first matrix and column from the second matrix
                result.m[col * 4 + row] =
                    m[0 * 4 + row] * mat.m[col * 4 + 0] +
                    m[1 * 4 + row] * mat.m[col * 4 + 1] +
                    m[2 * 4 + row] * mat.m[col * 4 + 2] +
                    m[3 * 4 + row] * mat.m[col * 4 + 3];
            }
        }
        return result;
    }

    // Translation matrix
    static Matrix4 translation(const Vector3& v) {
        Matrix4 result;
        // Place the translation vector in the last column of the matrix
        result.m[12] = v.x;
        result.m[13] = v.y;
        result.m[14] = v.z;
        return result;
    }

    /*
     * Rotation matrix around an arbitrary axis using Rodrigues' rotation formula.
     *
     * Mathematical Concept:
     * Given an axis (unit vector) and an angle, the rotation matrix can be constructed as:
     * R = I * cos(theta) + (1 - cos(theta)) * (axis ⊗ axis) + [axis]_x * sin(theta)
     * where [axis]_x is the skew-symmetric cross-product matrix of the axis.
     */
    static Matrix4 rotationAxis(const Vector3& axis, float angleDegrees) {
        Matrix4 result;
        float angleRadians = angleDegrees * 3.14159265f / 180.0f;
        float c = cosf(angleRadians);
        float s = sinf(angleRadians);
        float t = 1 - c;
        Vector3 a = axis.normalized();
        float x = a.x, y = a.y, z = a.z;

        // Populate the rotation matrix using Rodrigues' formula
        result.m[0] = t * x * x + c;
        result.m[1] = t * x * y + s * z;
        result.m[2] = t * x * z - s * y;
        result.m[3] = 0;

        result.m[4] = t * x * y - s * z;
        result.m[5] = t * y * y + c;
        result.m[6] = t * y * z + s * x;
        result.m[7] = 0;

        result.m[8] = t * x * z + s * y;
        result.m[9] = t * y * z - s * x;
        result.m[10] = t * z * z + c;
        result.m[11] = 0;

        result.m[12] = 0;
        result.m[13] = 0;
        result.m[14] = 0;
        result.m[15] = 1;

        return result;
    }

    /*
     * Perspective projection matrix.
     *
     * Mathematical Concept:
     * The perspective projection matrix transforms 3D coordinates into 2D coordinates with perspective.
     * It is defined by the field of view, aspect ratio, and near and far clipping planes.
     *
     * The matrix is constructed as follows:
     * [ f/aspect   0       0                       0                ]
     * [    0       f       0                       0                ]
     * [    0       0   (zFar+zNear)/(zNear-zFar)  (2*zFar*zNear)/(zNear-zFar) ]
     * [    0       0      -1                       0                ]
     * where f = 1/tan(fovY/2)
     */
    static Matrix4 perspective(float fovYDegrees, float aspect, float zNear, float zFar) {
        Matrix4 result;
        float f = 1.0f / tanf(fovYDegrees * 3.14159265f / 360.0f);

        result.m[0] = f / aspect;
        result.m[1] = 0;
        result.m[2] = 0;
        result.m[3] = 0;

        result.m[4] = 0;
        result.m[5] = f;
        result.m[6] = 0;
        result.m[7] = 0;

        result.m[8] = 0;
        result.m[9] = 0;
        result.m[10] = (zFar + zNear) / (zNear - zFar);
        result.m[11] = -1;

        result.m[12] = 0;
        result.m[13] = 0;
        result.m[14] = (2 * zFar * zNear) / (zNear - zFar);
        result.m[15] = 0;

        return result;
    }
};

// Function prototypes
void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void processInput(GLFWwindow* window);
unsigned int createShaderProgram();
void drawAxes(unsigned int shaderProgram);
void updateCameraAngles();

/*
 * framebuffer_size_callback:
 * Adjusts the OpenGL viewport when the window size changes.
 *
 * Parameters:
 * - window: The GLFW window that was resized.
 * - width: The new width of the window.
 * - height: The new height of the window.
 */
void framebuffer_size_callback(GLFWwindow* window, int w, int h)
{
    width = w;
    height = h;
    glViewport(0, 0, width, height);
}

/*
 * processInput:
 * Handles user input for zooming the camera in and out.
 *
 * Parameters:
 * - window: The GLFW window to poll input from.
 */
void processInput(GLFWwindow* window)
{
    const float distanceStep = 0.1f;

    // Close the window if the ESC key is pressed
    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);

    // Zoom in: Decrease the distance from the camera to the target
    if (glfwGetKey(window, GLFW_KEY_EQUAL) == GLFW_PRESS || glfwGetKey(window, GLFW_KEY_KP_ADD) == GLFW_PRESS)
    {
        distance -= distanceStep;
        if (distance < 1.0f) distance = 1.0f; // Prevent the camera from getting too close
    }

    // Zoom out: Increase the distance from the camera to the target
    if (glfwGetKey(window, GLFW_KEY_MINUS) == GLFW_PRESS || glfwGetKey(window, GLFW_KEY_KP_SUBTRACT) == GLFW_PRESS)
    {
        distance += distanceStep;
    }
}

/*
 * updateCameraAngles:
 * Automatically updates the camera's rotation angles based on the elapsed time.
 *
 * Mathematical Concept:
 * - The camera's horizontal angle (angleX) increases linearly over time to create a continuous rotation around the Y-axis.
 * - The vertical angle (angleY) oscillates sinusoidally to make the camera move up and down smoothly.
 *
 * Parameters:
 * - None
 */
void updateCameraAngles()
{
    const float rotationSpeed = 20.0f; // Degrees per second

    // Increment angleX based on rotation speed and time elapsed since last frame
    angleX += rotationSpeed * deltaTime;
    if (angleX >= 360.0f) angleX -= 360.0f;

    // Oscillate angleY between -15 and +15 degrees using a sine wave
    angleY = 15.0f * sinf(glfwGetTime());
}

/*
 * createShaderProgram:
 * Compiles the vertex and fragment shaders, links them into a shader program, and returns the program ID.
 *
 * Mathematical Concept:
 * - Shaders are small programs that run on the GPU to handle rendering. The vertex shader transforms vertex positions,
 *   and the fragment shader determines the color of each pixel.
 *
 * Returns:
 * - The ID of the compiled and linked shader program.
 */
unsigned int createShaderProgram()
{
    int success;
    char infoLog[512];

    // Vertex Shader
    unsigned int vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexShaderSource, NULL);
    glCompileShader(vertexShader);

    // Check for compile errors in Vertex Shader
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
    if (!success)
    {
        glGetShaderInfoLog(vertexShader, 512, NULL, infoLog);
        std::cerr << "ERROR: Vertex Shader Compilation Failed\n" << infoLog << std::endl;
    }

    // Fragment Shader
    unsigned int fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragmentShader, 1, &fragmentShaderSource, NULL);
    glCompileShader(fragmentShader);

    // Check for compile errors in Fragment Shader
    glGetShaderiv(fragmentShader, GL_COMPILE_STATUS, &success);
    if (!success)
    {
        glGetShaderInfoLog(fragmentShader, 512, NULL, infoLog);
        std::cerr << "ERROR: Fragment Shader Compilation Failed\n" << infoLog << std::endl;
    }

    // Shader Program Linking
    unsigned int shaderProgram = glCreateProgram();
    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);

    // Check for linking errors in Shader Program
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
    if (!success)
    {
        glGetProgramInfoLog(shaderProgram, 512, NULL, infoLog);
        std::cerr << "ERROR: Shader Program Linking Failed\n" << infoLog << std::endl;
    }

    // Delete shaders as they're now linked into the program and no longer needed
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    return shaderProgram;
}

/*
 * drawAxes:
 * Renders the X, Y, and Z axes centered at the origin.
 *
 * Mathematical Concepts:
 * - Model-View-Projection (MVP) Matrix: Transforms vertex positions from model space to clip space.
 * - Line Primitives: Used to draw the axes as lines in 3D space.
 *
 * Parameters:
 * - shaderProgram: The ID of the shader program to use for rendering.
 */
void drawAxes(unsigned int shaderProgram)
{
    // Define axis vertices: each axis is represented by two points (origin to positive direction)
    float axisVertices[] = {
        // Positions
         0.0f, 0.0f, 0.0f,  // Origin
         1.0f, 0.0f, 0.0f,  // X-axis
         0.0f, 0.0f, 0.0f,  // Origin
         0.0f, 1.0f, 0.0f,  // Y-axis
         0.0f, 0.0f, 0.0f,  // Origin
         0.0f, 0.0f, 1.0f   // Z-axis
    };

    // Static VAO and VBO to ensure they are created only once
    static unsigned int VAO = 0, VBO = 0;
    if (VAO == 0)
    {
        // Generate Vertex Array Object and Vertex Buffer Object
        glGenVertexArrays(1, &VAO);
        glGenBuffers(1, &VBO);

        // Bind VAO to store vertex attribute configuration
        glBindVertexArray(VAO);

        // Bind and buffer vertex data
        glBindBuffer(GL_ARRAY_BUFFER, VBO);
        glBufferData(GL_ARRAY_BUFFER, sizeof(axisVertices), axisVertices, GL_STATIC_DRAW);

        // Define vertex attribute pointers
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
        glEnableVertexAttribArray(0);
    }

    // Calculate view and projection matrices manually

    // Model matrix (identity) since axes are centered at the origin
    Matrix4 model;

    /*
     * Camera Position Calculation:
     *
     * Using spherical coordinates to position the camera around the target (origin).
     *
     * position.x = distance * cos(angleY) * sin(angleX)
     * position.y = distance * sin(angleY)
     * position.z = distance * cos(angleY) * cos(angleX)
     *
     * This places the camera at a certain distance from the origin, rotated by angleX around the Y-axis
     * and by angleY up/down.
     */
    float radAngleX = angleX * 3.14159265f / 180.0f;
    float radAngleY = angleY * 3.14159265f / 180.0f;

    Vector3 target(0.0f, 0.0f, 0.0f); // The point the camera is looking at
    Vector3 position;
    position.x = target.x + distance * cosf(radAngleY) * sinf(radAngleX);
    position.y = target.y + distance * sinf(radAngleY);
    position.z = target.z + distance * cosf(radAngleY) * cosf(radAngleX);

    // Define the up vector for the camera
    Vector3 up(0.0f, 1.0f, 0.0f);

    /*
     * View Matrix (LookAt Implementation):
     *
     * The view matrix transforms world coordinates to camera (view) coordinates.
     * It is constructed using the camera's position, target, and up vector.
     *
     * Mathematical Steps:
     * 1. Calculate the forward vector (f) as the normalized vector from position to target.
     * 2. Calculate the right vector (s) as the normalized cross product of f and up.
     * 3. Recalculate the up vector (u) as the cross product of s and f.
     * 4. Construct the view matrix using s, u, and -f, and apply a translation to move the world to the camera's position.
     */
    Vector3 f = (target - position).normalized(); // Forward vector
    Vector3 s = f.cross(up).normalized();         // Right vector
    Vector3 u = s.cross(f);                       // Recalculated Up vector

    Matrix4 view;
    view.m[0] = s.x;
    view.m[4] = s.y;
    view.m[8] = s.z;
    view.m[12] = 0;

    view.m[1] = u.x;
    view.m[5] = u.y;
    view.m[9] = u.z;
    view.m[13] = 0;

    view.m[2] = -f.x;
    view.m[6] = -f.y;
    view.m[10] = -f.z;
    view.m[14] = 0;

    view.m[3] = 0;
    view.m[7] = 0;
    view.m[11] = 0;
    view.m[15] = 1;

    // Translation matrix to move the world by the negative camera position
    Matrix4 translation = Matrix4::translation(-position);
    view = view * translation; // Combine rotation and translation

    /*
     * Projection Matrix:
     *
     * Transforms camera (view) coordinates into clip space using a perspective projection.
     * It simulates the effect of perspective, where objects farther away appear smaller.
     */
    float aspectRatio = (float)width / (float)height;
    Matrix4 projection = Matrix4::perspective(45.0f, aspectRatio, 0.1f, 100.0f);

    /*
     * Model-View-Projection (MVP) Matrix:
     *
     * Combines the model, view, and projection matrices into a single matrix.
     * This matrix is used to transform vertex positions from model space directly to clip space.
     */
    Matrix4 mvp = projection * view * model;

    // Use the shader program
    glUseProgram(shaderProgram);

    // Set the MVP matrix uniform in the vertex shader
    int mvpLoc = glGetUniformLocation(shaderProgram, "uMVP");
    glUniformMatrix4fv(mvpLoc, 1, GL_FALSE, mvp.m);

    // Bind the VAO containing the axis vertices
    glBindVertexArray(VAO);

    // Draw X-axis in red
    glUniform3f(glGetUniformLocation(shaderProgram, "uColor"), 1.0f, 0.0f, 0.0f);
    glDrawArrays(GL_LINES, 0, 2);

    // Draw Y-axis in green
    glUniform3f(glGetUniformLocation(shaderProgram, "uColor"), 0.0f, 1.0f, 0.0f);
    glDrawArrays(GL_LINES, 2, 2);

    // Draw Z-axis in blue
    glUniform3f(glGetUniformLocation(shaderProgram, "uColor"), 0.0f, 0.0f, 1.0f);
    glDrawArrays(GL_LINES, 4, 2);

    // Unbind the VAO to prevent accidental modifications
    glBindVertexArray(0);
}

/*
 * main:
 * The entry point of the application. Initializes GLFW and glad, sets up the window, compiles shaders,
 * and enters the render loop where it continuously updates the camera and renders the scene.
 */
int main()
{
    // Initialize GLFW
    if (!glfwInit())
    {
        std::cerr << "Failed to initialize GLFW" << std::endl;
        return -1;
    }

    // Set GLFW window hints for OpenGL version and profile
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3); // OpenGL major version
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3); // OpenGL minor version
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE); // Use the core profile
    // Enable forward compatibility on MacOS
#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
#endif

    // Create a GLFWwindow object
    window = glfwCreateWindow(width, height, "Camera Rotation Around Center", NULL, NULL);
    if (window == NULL)
    {
        std::cerr << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return -1;
    }
    glfwMakeContextCurrent(window);

    // Set the framebuffer resize callback to adjust the viewport when the window size changes
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);

    // Load OpenGL function pointers using glad
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
    {
        std::cerr << "Failed to initialize glad" << std::endl;
        return -1;
    }

    // Compile and link shaders into a shader program
    unsigned int shaderProgram = createShaderProgram();

    // Enable depth testing to ensure correct rendering of 3D objects
    glEnable(GL_DEPTH_TEST);

    // Render loop: runs until the window should close
    while (!glfwWindowShouldClose(window))
    {
        // Calculate delta time (time between current frame and last frame)
        float currentFrame = glfwGetTime();
        deltaTime = currentFrame - lastFrame;
        lastFrame = currentFrame;

        // Handle user input for zooming
        processInput(window);

        // Update camera angles automatically based on elapsed time
        updateCameraAngles();

        // Clear the color and depth buffers to prepare for new frame
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f); // Set clear color to black
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // Draw the coordinate axes
        drawAxes(shaderProgram);

        // Swap the front and back buffers to display the rendered frame
        glfwSwapBuffers(window);
        // Poll for and process events (like keyboard and mouse input)
        glfwPollEvents();
    }

    // Clean up resources by deleting the shader program
    glDeleteProgram(shaderProgram);

    // Terminate GLFW to free allocated resources
    glfwTerminate();
    return 0;
}
