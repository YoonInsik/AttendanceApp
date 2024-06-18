package com.cookandroid.attendanceapp;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import com.google.android.gms.tasks.OnCompleteListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.auth.AuthResult;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;

public class LoginActivity extends AppCompatActivity {

    private EditText etEmail, etPassword;
    private Button btnLogin;
    private TextView textViewRegister;
    private FirebaseAuth mAuth;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_login);

        etEmail = findViewById(R.id.etEmail);
        etPassword = findViewById(R.id.etPassword);
        btnLogin = findViewById(R.id.btnLogin);
        textViewRegister = findViewById(R.id.textViewRegister);

        mAuth = FirebaseAuth.getInstance();

        btnLogin.setOnClickListener(v -> {
            String username = etEmail.getText().toString();
            String password = etPassword.getText().toString();
            Login(username, password);
        });

        textViewRegister.setOnClickListener(v -> {
            String username = etEmail.getText().toString();
            String password = etPassword.getText().toString();
            Register(username, password);
        });
    }

    private void Login(String email, String password) {
        if (email.isEmpty() || password.isEmpty()) {
            Toast.makeText(this, "이메일 혹은 비밀번호를 입력하세요", Toast.LENGTH_SHORT).show();
        }
        else {
            mAuth.signInWithEmailAndPassword(email, password)
                    .addOnCompleteListener(this, new OnCompleteListener<AuthResult>() {
                        @Override
                        public void onComplete(@NonNull Task<AuthResult> task) {
                            if (task.isSuccessful()) {
                                Log.d("로그인", "signInWithEmail:success");
                                Toast.makeText(LoginActivity.this, "로그인 성공", Toast.LENGTH_SHORT).show();
                                FirebaseUser user = mAuth.getCurrentUser();
                                Intent intent = new Intent(LoginActivity.this, AttendanceActivity.class);
                                startActivity(intent);
                            } else {
                                Log.e("로그인", task.getException().toString());
                                Toast.makeText(LoginActivity.this, "로그인 실패", Toast.LENGTH_SHORT).show();
                            }
                        }
                    });
        }
    }

    private void Register(String email, String password) {
        if (email.isEmpty() || password.isEmpty()) {
            Toast.makeText(this, "이메일 혹은 비밀번호를 입력하세요", Toast.LENGTH_SHORT).show();
        }
        else {
            mAuth.createUserWithEmailAndPassword(email, password)
                    .addOnCompleteListener(this, task -> {
                        if (task.isSuccessful()) {
                            Toast.makeText(this, "계정 생성 완료.", Toast.LENGTH_SHORT).show();
                        } else {
                            Toast.makeText(this, "계정 생성 실패", Toast.LENGTH_SHORT).show();
                        }
                    });
        }
    }
}
