import 'dart:ui';
import 'package:flutter/material.dart';

class ModernTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const ModernTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icons = [
      Icons.home_outlined,
      Icons.people_outline,
      Icons.menu_book_outlined,
      Icons.search_outlined,
      Icons.person_outline,
    ];

    final activeIcons = [
      Icons.home,
      Icons.people,
      Icons.menu_book,
      Icons.search,
      Icons.person,
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          12,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 20,
              sigmaY: 20,
            ),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(36),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceAround,

                children: List.generate(
                  5,
                  (index) {
                    final selected =
                        currentIndex == index;

                    return GestureDetector(
                      onTap: () => onTap(index),

                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 250),

                        width: 56,
                        height: 56,

                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.black.withOpacity(0.08)
                              : Colors.transparent,

                          borderRadius:
                              BorderRadius.circular(28),
                        ),

                        child: Icon(
                          selected
                              ? activeIcons[index]
                              : icons[index],
                          size: 27,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}