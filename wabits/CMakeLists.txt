project(wabits)

add_executable(wabits
    wabits.c
)

if(WIN32)
    target_link_libraries(wabits wsock32)
endif()
