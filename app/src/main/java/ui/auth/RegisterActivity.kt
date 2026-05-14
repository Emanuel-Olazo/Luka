package com.luka.finanzas.ui.auth

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.luka.finanzas.databinding.ActivityRegisterBinding
import com.luka.finanzas.repository.FirebaseRepository
import com.luka.finanzas.ui.main.MainActivity
import kotlinx.coroutines.launch

class RegisterActivity : AppCompatActivity() {

    private lateinit var binding: ActivityRegisterBinding
    private val repo = FirebaseRepository()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityRegisterBinding.inflate(layoutInflater)
        setContentView(binding.root)

        binding.btnRegister.setOnClickListener {
            val name = binding.etName.text.toString().trim()
            val email = binding.etEmail.text.toString().trim()
            val password = binding.etPassword.text.toString()

            if (name.isEmpty() || email.isEmpty() || password.length < 6) {
                Toast.makeText(this, "Completa todos los campos (mín. 6 caracteres en contraseña)",
                    Toast.LENGTH_SHORT).show()
                return@setOnClickListener
            }
            lifecycleScope.launch {
                val result = repo.register(email, password, name)
                if (result.isSuccess) {
                    repo.seedDefaultCategories()
                    startActivity(Intent(this@RegisterActivity, MainActivity::class.java))
                    finish()
                } else {
                    Toast.makeText(this@RegisterActivity,
                        "Error: ${result.exceptionOrNull()?.message}", Toast.LENGTH_LONG).show()
                }
            }
        }

        binding.btnBackLogin.setOnClickListener { finish() }
    }
}