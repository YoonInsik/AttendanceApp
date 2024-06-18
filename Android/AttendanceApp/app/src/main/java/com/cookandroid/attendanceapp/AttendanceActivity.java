package com.cookandroid.attendanceapp;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.Exclude;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.IgnoreExtraProperties;
import com.google.firebase.database.ValueEventListener;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

public class AttendanceActivity extends AppCompatActivity {

    private ListView attendanceListView;
    private ArrayList<String> attendanceList;
    private ArrayAdapter<String> adapter;
    private Button clockInOutBtn;

    private FirebaseDatabase database;
    private String userId;
    private DatabaseReference userRef;
    private DatabaseReference clockRef;
    private String clockInOut;

    private TextView currentTimeTextView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_attendance);

        attendanceListView = findViewById(R.id.attendanceListView);
        clockInOutBtn = findViewById(R.id.clockInOutbtn);
        currentTimeTextView = findViewById(R.id.currentTimeTextView);

        database = FirebaseDatabase.getInstance();
        userId = FirebaseAuth.getInstance().getCurrentUser().getUid();
        userRef = database.getReference("attendance/" + userId);
        clockRef = userRef.child("ClockInOut");

        clockInOutBtn.setOnClickListener(v -> {
            ClockInOut();
        });

        clockInOut = "out"; // 초기화ㅁ
        attendanceList = new ArrayList<String>();
        adapter = new ArrayAdapter<>(this, android.R.layout.simple_list_item_1, attendanceList);
        clockRef.addValueEventListener(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                attendanceList.clear();

                for (DataSnapshot dateSnapshot : dataSnapshot.getChildren()) {
                    String inout = (dateSnapshot.child("inout").getValue(String.class).equals("in")) ? "출근" : "퇴근";
                    String date = dateSnapshot.child("date").getValue(String.class);
                    String listItem = inout + " " + date;
                    Log.i("Firebase", "리스트아이템: " + " " + listItem);
                    attendanceList.add((listItem));
                }

                attendanceListView.setAdapter(adapter);
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {
                //Log.w(TAG, "loadPost:onCancelled", databaseError.toException());
            }
        });

        clockRef.orderByChild("date").limitToLast(1).addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot dataSnapshot) {
                for (DataSnapshot dateSnapshot: dataSnapshot.getChildren()) {
                    Log.i("Firebase", dateSnapshot.getKey() + " " + dateSnapshot.child("inout").getValue(String.class));
                    clockInOut = dateSnapshot.child("inout").getValue(String.class);
                    UpdateButtonState();
                }
            }

            @Override
            public void onCancelled(DatabaseError databaseError) {
                throw databaseError.toException();
            }
        });

        Thread timeThread = new Thread() {
            @Override
            public void run() {
                try {
                    while (!isInterrupted()) {
                        Thread.sleep(1000);
                        runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                currentTimeTextView.setText(GetCurrentTime());
                            }
                        });
                    }
                } catch (InterruptedException e) {
                }
            }
        };
        timeThread.start();
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        super.onCreateOptionsMenu(menu);
        menu.add(0, 1, 0, "로그아웃");
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(@NonNull MenuItem item) {
        switch (item.getItemId()) {
            case 1:
                FirebaseAuth.getInstance().signOut();
                Intent intent = new Intent(AttendanceActivity.this, LoginActivity.class);
                startActivity(intent);
                return true;
        }
        return super.onOptionsItemSelected(item);
    }

    // 출퇴근
    private void ClockInOut() {
        String newKey = userRef.child("ClockInOut").push().getKey();
        String date = GetCurrentTime();
        clockInOut = (clockInOut.equals("in")) ? "out" : "in";
        Post post = new Post(clockInOut, date);
        Map<String, Object> postValues = post.toMap();

        Map<String, Object> childUpdates = new HashMap<>();
        childUpdates.put("/ClockInOut/" + newKey, postValues);

        userRef.updateChildren(childUpdates).addOnCompleteListener(task -> {
            if (task.isSuccessful()) {
                // 버튼 갱신 및 UI 업데이트
                UpdateButtonState();
            } else {
                // 실패 처리
                Toast.makeText(AttendanceActivity.this, "Clock in failed.", Toast.LENGTH_SHORT).show();
            }
        });
    }

    // 버튼 상태 업데이트 함수
    private void UpdateButtonState() {
        if (clockInOut.equals("in")) {
            clockInOutBtn.setText("퇴근하기");
        } else {
            clockInOutBtn.setText("출근하기");
        }
    }

    // 현재 시간을 가져오는 함수
    private String GetCurrentTime() {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault());
        return sdf.format(new Date());
    }
}

@IgnoreExtraProperties
class Post {
    public String inout;
    public String date;

    public Post() {
        // Default constructor required for calls to DataSnapshot.getValue(Post.class)
    }

    public Post(String inout, String date) {
        this.inout = inout;
        this.date = date;
    }

    @Exclude
    public Map<String, Object> toMap() {
        HashMap<String, Object> result = new HashMap<>();
        result.put("inout", inout);
        result.put("date", date);

        return result;
    }
}